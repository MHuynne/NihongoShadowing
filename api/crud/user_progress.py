from sqlalchemy.orm import Session
from models.user_progress import UserProgress
from schemas.user_progress import UserProgressCreate, UserProgressUpdate


def get_progress(db: Session, user_firebase_id: str, lesson_id: int) -> UserProgress | None:
    """Lấy tiến độ của 1 user cho 1 lesson cụ thể."""
    return (
        db.query(UserProgress)
        .filter(
            UserProgress.user_firebase_id == user_firebase_id,
            UserProgress.lesson_id == lesson_id,
        )
        .first()
    )


def get_all_progress(db: Session, user_firebase_id: str) -> list[UserProgress]:
    """Lấy toàn bộ tiến độ của 1 user (dùng cho Roadmap Screen)."""
    return (
        db.query(UserProgress)
        .filter(UserProgress.user_firebase_id == user_firebase_id)
        .all()
    )


def upsert_progress(
    db: Session,
    user_firebase_id: str,
    lesson_id: int,
    data: UserProgressUpdate,
) -> UserProgress:
    """Tạo mới hoặc cập nhật tiến độ (upsert). Chỉ ghi field nào được gửi."""
    record = get_progress(db, user_firebase_id, lesson_id)

    if record is None:
        # Tạo mới
        record = UserProgress(
            user_firebase_id=user_firebase_id,
            lesson_id=lesson_id,
        )
        db.add(record)

    # Cập nhật từng field (chỉ các field không phải None)
    update_data = data.model_dump(exclude_none=True)
    for field, value in update_data.items():
        setattr(record, field, value)

    # Tự động tính lesson_completed nếu chưa được set thủ công
    if "lesson_completed" not in update_data:
        # Chỉ auto-complete nếu cả test lẫn shadowing đã qua
        record.lesson_completed = bool(record.test_passed and record.shadowing_passed)
    # Nếu request đã set lesson_completed=True thì giữ nguyên (đã được setattr ở trên)

    db.commit()
    db.refresh(record)
    return record


def delete_progress(db: Session, user_firebase_id: str, lesson_id: int) -> bool:
    """Xoá tiến độ (dùng khi reset lesson)."""
    record = get_progress(db, user_firebase_id, lesson_id)
    if record:
        db.delete(record)
        db.commit()
        return True
    return False
