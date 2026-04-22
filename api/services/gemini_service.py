import json
import os
import google.generativeai as genai
from typing import List
from schemas.roleplay import ChatResponseResp, GrammarCorrectionSchema

# Cấu hình API Key cho Gemini (lấy tự động từ file .env)
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

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
        
        # Thiết lập model (hỗ trợ ép kiểu JSON trả về)
        model = genai.GenerativeModel(
            model_name=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
            system_instruction=system_instruction,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json",
                temperature=0.7
            )
        )
        
        # Chuyển đổi định dạng lịch sử chat thành định dạng của Gemini (user và model)
        gemini_history = []
        for msg in chat_history:
            gemini_role = "user" if msg["role"] == "user" else "model"
            gemini_history.append({"role": gemini_role, "parts": [msg["content"]]})
            
        chat = model.start_chat(history=gemini_history)

        try:
            response = await chat.send_message_async(user_message)
            content = response.text
            
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
            print("Lỗi từ Gemini API:", str(e))
            return ChatResponseResp(
                ai_reply="[System Error] Có lỗi xảy ra khi kết nối tới AI.",
                suggestions=[],
                grammar_correction=None
            )
