from sqlalchemy.orm import Session
from models.roleplay import RoleplayScenario, RoleplaySession, RoleplayMessage
from schemas.roleplay import SessionCreateReq, RoleplayScenarioBase

def get_scenarios(db: Session):
    """Lấy danh sách kịch bản roleplay"""
    return db.query(RoleplayScenario).all()

def create_scenario(db: Session, scenario_req: RoleplayScenarioBase):
    """Tạo một kịch bản mới (dành cho bối cảnh tự chọn)"""
    db_scenario = RoleplayScenario(
        title=scenario_req.title,
        description=scenario_req.description,
        icon_url=scenario_req.icon_url
    )
    db.add(db_scenario)
    db.commit()
    db.refresh(db_scenario)
    return db_scenario

def create_session(db: Session, session_req: SessionCreateReq):
    """Tạo một phiên trò chuyện mới"""
    db_session = RoleplaySession(
        scenario_id=session_req.scenario_id,
        user_id=session_req.user_id,
        mode=session_req.mode
    )
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

def get_session(db: Session, session_id: int):
    """Lấy thông tin phiên trò chuyện"""
    return db.query(RoleplaySession).filter(RoleplaySession.id == session_id).first()

def update_session_mode(db: Session, session_id: int, mode: str):
    """Cập nhật chế độ hội thoại (Keigo/Plain) cho phiên đang diễn ra"""
    db_session = get_session(db, session_id)
    if db_session:
        db_session.mode = mode
        db.commit()
        db.refresh(db_session)
    return db_session

def get_session_messages(db: Session, session_id: int):
    """Lấy lịch sử tin nhắn của một phiên"""
    return db.query(RoleplayMessage).filter(RoleplayMessage.session_id == session_id).order_by(RoleplayMessage.created_at.asc()).all()

def get_user_sessions(db: Session, user_id: int):
    return (
        db.query(RoleplaySession)
        .filter(RoleplaySession.user_id == user_id)
        .order_by(RoleplaySession.created_at.desc())
        .all()
    )

def get_last_session_message(db: Session, session_id: int):
    return (
        db.query(RoleplayMessage)
        .filter(RoleplayMessage.session_id == session_id)
        .order_by(RoleplayMessage.created_at.desc())
        .first()
    )

def count_session_messages(db: Session, session_id: int):
    return (
        db.query(RoleplayMessage)
        .filter(RoleplayMessage.session_id == session_id)
        .count()
    )

def create_message(db: Session, session_id: int, role: str, content: str, grammar_correction: dict = None, suggestions: list = None):
    """Lưu tin nhắn của user hoặc AI vào database"""
    db_msg = RoleplayMessage(
        session_id=session_id,
        role=role,
        content=content,
        grammar_correction=grammar_correction,
        suggestions=suggestions
    )
    db.add(db_msg)
    db.commit()
    db.refresh(db_msg)
    return db_msg
