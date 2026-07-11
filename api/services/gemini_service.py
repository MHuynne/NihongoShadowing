import asyncio
import json
import os
from typing import List

from google import genai
from google.genai import types

from schemas.roleplay import ChatResponseResp, GrammarCorrectionSchema


_main_key = os.getenv("GEMINI_API_KEY", "")
_raw_keys = os.getenv("GEMINI_API_KEYS", "")
_GEMINI_KEY_POOL = [key.strip() for key in _raw_keys.split(",") if key.strip()]

if _main_key and _main_key not in _GEMINI_KEY_POOL:
    _GEMINI_KEY_POOL.insert(0, _main_key)

_current_key_index = 0


def _get_next_api_key() -> str:
    global _current_key_index
    if not _GEMINI_KEY_POOL:
        return ""
    key = _GEMINI_KEY_POOL[_current_key_index % len(_GEMINI_KEY_POOL)]
    _current_key_index += 1
    return key


_client = genai.Client(api_key=_GEMINI_KEY_POOL[0] if _GEMINI_KEY_POOL else _main_key)


def _is_quota_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return (
        "resource_exhausted" in message
        or "429" in message
        or "quota" in message
        or "credits are depleted" in message
        or "prepayment credits" in message
        or "too many requests" in message
    )


def _fallback_reply(mode: str, quota_limited: bool = False) -> ChatResponseResp:
    if mode == "plain":
        ai_reply = (
            "今はAI接続が混み合っているみたい。練習は続けよう。"
            "まず、もう少し詳しく話してくれる？"
        )
        suggestions = [
            "うん、もう少し説明するね。",
            "例えば、こんな状況なんだ。",
            "あなたならどう思う？",
        ]
    else:
        ai_reply = (
            "現在AIサービスに接続できませんが、練習は続けられます。"
            "恐れ入りますが、もう少し詳しくお話しいただけますか。"
        )
        suggestions = [
            "はい、もう少し詳しくご説明いたします。",
            "例えば、このような状況でございます。",
            "ご意見を伺ってもよろしいでしょうか。",
        ]

    return ChatResponseResp(
        ai_reply=ai_reply,
        suggestions=suggestions,
        grammar_correction=None,
        retry_after_seconds=60 if quota_limited else None,
    )


class RoleplayAIService:
    @staticmethod
    async def generate_reply(
        scenario_title: str,
        scenario_desc: str,
        mode: str,
        chat_history: List[dict],
        user_message: str,
    ) -> ChatResponseResp:
        global _client
        system_instruction = f"""
You are an AI Japanese conversation partner playing a role in a roleplay scenario.
Scenario: {scenario_title}
Context: {scenario_desc}
Politeness Mode: {mode.upper()}
(If mode is KEIGO, you and the user MUST communicate in formal Keigo/Teineigo. If mode is PLAIN, you both MUST communicate in casual/plain form.)

Your tasks:
1. Reply naturally to the user in character.
2. Evaluate the user's LATEST message. If they make a grammatical error, use unnatural phrasing, or violate the requested {mode.upper()} mode, provide a correction. If it is perfectly fine, return null.
3. Provide exactly 3 suggestions for what the user could realistically say next to continue the conversation.

You MUST completely adhere to the following JSON structure. Output only valid JSON without any markdown block formatting code.
{{
    "ai_reply": "Your in-character conversational response in Japanese.",
    "suggestions": ["Next thing user could say 1", "Next thing user could say 2", "Next thing user could say 3"],
    "grammar_correction": null OR {{
        "error": "The wrongly phrased part of the user's sentence",
        "correction": "The corrected Japanese phrase",
        "explanation": "Short explanation in Vietnamese of why it was wrong."
    }}
}}
"""

        _config = types.GenerateContentConfig(
            system_instruction=system_instruction,
            response_mime_type="application/json",
            temperature=0.7,
        )
        model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")


        contents = []
        for msg in chat_history:
            role = "user" if msg["role"] == "user" else "model"
            contents.append(types.Content(role=role, parts=[types.Part(text=msg["content"])]))
        contents.append(types.Content(role="user", parts=[types.Part(text=user_message)]))

        max_retries = max(len(_GEMINI_KEY_POOL), 1)
        for attempt in range(max_retries):
            try:
                response = await _client.aio.models.generate_content(
                    model=model_name,
                    contents=contents,
                    config=_config,
                )
                parsed = json.loads(response.text)

                grammar = None
                if parsed.get("grammar_correction"):
                    grammar = GrammarCorrectionSchema(**parsed["grammar_correction"])

                return ChatResponseResp(
                    ai_reply=parsed.get(
                        "ai_reply",
                        "すみません、もう一度お願いします。",
                    ),
                    suggestions=parsed.get("suggestions", []),
                    grammar_correction=grammar,
                )
            except Exception as exc:
                quota_limited = _is_quota_error(exc)
                if quota_limited and attempt < max_retries - 1:
                    next_key = _get_next_api_key()
                    suffix = next_key[-6:] if next_key else "empty"
                    print(f"[roleplay] Gemini quota hit. Retrying with key ...{suffix}")
                    _client = genai.Client(api_key=next_key)
                    await asyncio.sleep(1)
                    continue

                safe_error = str(exc).encode("ascii", "ignore").decode("ascii")
                print(f"[roleplay] Gemini API error: {type(exc).__name__}: {safe_error}")
                return _fallback_reply(mode=mode, quota_limited=quota_limited)

        return _fallback_reply(mode=mode, quota_limited=True)