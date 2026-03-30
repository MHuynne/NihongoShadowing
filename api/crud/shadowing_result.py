from sqlalchemy.orm import Session
from models.shadowing_result import ShadowingResult
from schemas.shadowing_result import ShadowingResultCreate

def create_result(db: Session, result: ShadowingResultCreate):
    db_result = ShadowingResult(
        user_id=result.user_id,
        topic_id=result.topic_id,
        overall_score=result.overall_score,
        detail_scores=result.detail_scores,
        user_audio_url=result.user_audio_url,
        mode=result.mode.value if result.mode else None
    )
    db.add(db_result)
    db.commit()
    db.refresh(db_result)
    return db_result

def get_results_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(ShadowingResult).filter(ShadowingResult.user_id == user_id).offset(skip).limit(limit).all()
