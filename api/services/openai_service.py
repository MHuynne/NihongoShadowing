import json
from openai import AsyncOpenAI
import os
from typing import List
from schemas.roleplay import ChatResponseResp, GrammarCorrectionSchema

client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

class RoleplayAIService:
    @staticmethod
    async def generate_reply(scenario_title: str, scenario_desc: str, mode: str, chat_history: List[dict], user_message: str) -> ChatResponseResp:
        # Định nghĩa Prompt
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

You MUST completely adhere to the following JSON structure. Output only valid JSON.
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
        
        messages = [{"role": "system", "content": system_instruction}]
        
        # Thêm lịch sử trò chuyện
        for msg in chat_history:
            messages.append({"role": msg["role"], "content": msg["content"]})
            
        messages.append({"role": "user", "content": user_message})

        try:
            response = await client.chat.completions.create(
                model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
                messages=messages,
                response_format={"type": "json_object"},
                temperature=0.7
            )

            content = response.choices[0].message.content
            parsed = json.loads(content)
            
            # Khởi tạo schema an toàn
            grammar = None
            if parsed.get("grammar_correction"):
                grammar = GrammarCorrectionSchema(**parsed["grammar_correction"])
                
            return ChatResponseResp(
                ai_reply=parsed.get("ai_reply", "すみません、もう一度お願いします。"),
                suggestions=parsed.get("suggestions", []),
                grammar_correction=grammar
            )
        except Exception as e:
            print("Lỗi từ OpenAI API:", str(e))
            return ChatResponseResp(
                ai_reply="[System Error] Có lỗi xảy ra khi kết nối tới AI.",
                suggestions=[],
                grammar_correction=None
            )
