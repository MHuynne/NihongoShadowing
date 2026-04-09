from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from crud import roleplay as crud_roleplay
from schemas import roleplay as schemas_roleplay
from services.gemini_service import RoleplayAIService

router = APIRouter(
    prefix="/roleplay",
    tags=["Roleplay Contextual"]
)

@router.get("/scenarios", response_model=List[schemas_roleplay.RoleplayScenarioResp])
def get_scenarios(db: Session = Depends(get_db)):
    """Lấy danh sách các kịch bản roleplay có sẵn"""
    scenarios = crud_roleplay.get_scenarios(db)
    return scenarios

@router.post("/session", response_model=schemas_roleplay.SessionResp)
def create_session(session_req: schemas_roleplay.SessionCreateReq, db: Session = Depends(get_db)):
    """Tạo một phiên trò chuyện roleplay mới"""
    new_session = crud_roleplay.create_session(db, session_req)
    return new_session

@router.patch("/session/{session_id}/mode", response_model=schemas_roleplay.SessionResp)
def update_mode(session_id: int, mode_req: schemas_roleplay.SessionModeUpdateReq, db: Session = Depends(get_db)):
    """Đổi chế độ (Keigo/Plain) ngay giữa phiên trò chuyện tương ứng với Nút Gạt Của User"""
    session = crud_roleplay.update_session_mode(db, session_id, mode_req.mode)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session

@router.post("/chat", response_model=schemas_roleplay.ChatResponseResp)
async def chat_with_ai(chat_req: schemas_roleplay.ChatRequestReq, db: Session = Depends(get_db)):
    """Gửi tin nhắn vào phiên và nhận phản hồi từ AI"""
    # 1. Lấy thông tin session
    session = crud_roleplay.get_session(db, chat_req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    scenario = session.scenario
    if not scenario:
        raise HTTPException(status_code=404, detail="Scenario not found")

    # 2. Lấy lịch sử trò chuyện TRƯỚC KHI lưu tin nhắn mới để AI không bị lặp lại tin nhắn user trong lịch sử
    db_messages = crud_roleplay.get_session_messages(db, chat_req.session_id)
    chat_history = [{"role": msg.role, "content": msg.content} for msg in db_messages]

    # 3. Lưu tin nhắn của người dùng vào Database
    crud_roleplay.create_message(
        db=db,
        session_id=chat_req.session_id,
        role="user",
        content=chat_req.message
    )

    # 4. Gọi OpenAI Service
    ai_response = await RoleplayAIService.generate_reply(
        scenario_title=scenario.title,
        scenario_desc=scenario.description or "",
        mode=session.mode.value,
        chat_history=chat_history,
        user_message=chat_req.message
    )

    # 5. Lưu tin nhắn trả về của AI vào Database
    # Sử dụng dict thay vì object để schema JSON tương thích với db Column JSON
    grammar_dict = ai_response.grammar_correction.model_dump() if ai_response.grammar_correction else None
    
    crud_roleplay.create_message(
        db=db,
        session_id=chat_req.session_id,
        role="assistant",
        content=ai_response.ai_reply,
        grammar_correction=grammar_dict,
        suggestions=ai_response.suggestions
    )

    return ai_response
