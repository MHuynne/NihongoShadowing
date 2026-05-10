from sqlalchemy.orm import Session

from models.roleplay import RoleplayMessage, RoleplayScenario, RoleplaySession
from schemas.roleplay import RoleplayScenarioBase, SessionCreateReq


def get_scenarios(db: Session):
    return db.query(RoleplayScenario).all()


def get_scenario(db: Session, scenario_id: int):
    return db.query(RoleplayScenario).filter(RoleplayScenario.id == scenario_id).first()


def create_scenario(db: Session, scenario_req: RoleplayScenarioBase):
    db_scenario = RoleplayScenario(
        title=scenario_req.title,
        description=scenario_req.description,
        icon_url=scenario_req.icon_url,
    )
    db.add(db_scenario)
    db.commit()
    db.refresh(db_scenario)
    return db_scenario


def update_scenario(db: Session, scenario_id: int, scenario_req: RoleplayScenarioBase):
    db_scenario = get_scenario(db, scenario_id)
    if db_scenario is None:
        return None

    db_scenario.title = scenario_req.title
    db_scenario.description = scenario_req.description
    db_scenario.icon_url = scenario_req.icon_url
    db.commit()
    db.refresh(db_scenario)
    return db_scenario


def delete_scenario(db: Session, scenario_id: int):
    db_scenario = get_scenario(db, scenario_id)
    if db_scenario:
        db.delete(db_scenario)
        db.commit()
    return db_scenario


def create_session(db: Session, session_req: SessionCreateReq):
    db_session = RoleplaySession(
        scenario_id=session_req.scenario_id,
        user_id=session_req.user_id,
        mode=session_req.mode,
    )
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session


def get_session(db: Session, session_id: int):
    return db.query(RoleplaySession).filter(RoleplaySession.id == session_id).first()


def update_session_mode(db: Session, session_id: int, mode: str):
    db_session = get_session(db, session_id)
    if db_session:
        db_session.mode = mode
        db.commit()
        db.refresh(db_session)
    return db_session


def get_session_messages(db: Session, session_id: int):
    return (
        db.query(RoleplayMessage)
        .filter(RoleplayMessage.session_id == session_id)
        .order_by(RoleplayMessage.created_at.asc())
        .all()
    )


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


def create_message(
    db: Session,
    session_id: int,
    role: str,
    content: str,
    grammar_correction: dict = None,
    suggestions: list = None,
):
    db_msg = RoleplayMessage(
        session_id=session_id,
        role=role,
        content=content,
        grammar_correction=grammar_correction,
        suggestions=suggestions,
    )
    db.add(db_msg)
    db.commit()
    db.refresh(db_msg)
    return db_msg
