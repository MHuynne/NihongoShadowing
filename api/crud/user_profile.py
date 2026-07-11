from sqlalchemy.orm import Session
from models.user_profile import UserProfile


def get_profile(db: Session, user_firebase_id: str) -> UserProfile | None:
    """Lấy profile của user."""
    return db.query(UserProfile).filter(UserProfile.user_firebase_id == user_firebase_id).first()


def upsert_profile_level(db: Session, user_firebase_id: str, jlpt_level: str) -> UserProfile:
    """Cập nhật hoặc tạo mới cấp độ JLPT cho user (upsert)."""
    profile = get_profile(db, user_firebase_id)

    if profile is None:
        profile = UserProfile(
            user_firebase_id=user_firebase_id,
            jlpt_level=jlpt_level
        )
        db.add(profile)
    else:
        profile.jlpt_level = jlpt_level

    db.commit()
    db.refresh(profile)
    return profile