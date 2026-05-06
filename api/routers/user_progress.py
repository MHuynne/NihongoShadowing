from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from schemas import user_progress as schemas
from crud import user_progress as crud

router = APIRouter(
    prefix="/progress",
    tags=["User Progress"],
)


def _get_uid(x_firebase_uid: Optional[str] = Header(None)) -> str:
    """Lấy Firebase UID từ header X-Firebase-UID.
    Flutter gửi kèm header này sau khi đăng nhập Firebase.
    """
    if not x_firebase_uid:
        raise HTTPException(status_code=401, detail="Thiếu header X-Firebase-UID")
    return x_firebase_uid


# ── GET /progress/ — Toàn bộ tiến độ của user ─────────────────────────────────
@router.get("/", response_model=List[schemas.UserProgress])
def get_all_progress(
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Lấy tiến độ tất cả lesson của user hiện tại (dùng cho Roadmap Screen)."""
    return crud.get_all_progress(db, user_firebase_id=uid)


# ── GET /progress/{lesson_id} — Tiến độ của 1 lesson ─────────────────────────
@router.get("/{lesson_id}", response_model=schemas.UserProgress)
def get_lesson_progress(
    lesson_id: int,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Lấy tiến độ của user cho 1 lesson cụ thể."""
    record = crud.get_progress(db, user_firebase_id=uid, lesson_id=lesson_id)
    if record is None:
        # Trả về trạng thái mặc định (chưa bắt đầu) thay vì 404
        return schemas.UserProgress(
            id=0,
            user_firebase_id=uid,
            lesson_id=lesson_id,
            flashcard_done=False,
            test_score=None,
            test_passed=False,
            shadowing_score=None,
            shadowing_passed=False,
            lesson_completed=False,
        )
    return record


# ── PATCH /progress/{lesson_id} — Cập nhật tiến độ ───────────────────────────
@router.patch("/{lesson_id}", response_model=schemas.UserProgress)
def update_progress(
    lesson_id: int,
    body: schemas.UserProgressUpdate,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """
    Cập nhật tiến độ học của user cho 1 lesson.
    Chỉ gửi các field cần thay đổi.

    Ví dụ:
    - Sau Flashcard:  { "flashcard_done": true }
    - Sau Test:       { "test_score": 85.0, "test_passed": true }
    - Sau Shadowing:  { "shadowing_score": 90.0, "shadowing_passed": true }
    """
    return crud.upsert_progress(
        db,
        user_firebase_id=uid,
        lesson_id=lesson_id,
        data=body,
    )


# ── DELETE /progress/{lesson_id} — Reset tiến độ 1 lesson ────────────────────
@router.delete("/{lesson_id}", status_code=204)
def reset_progress(
    lesson_id: int,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Reset toàn bộ tiến độ của user cho 1 lesson (học lại từ đầu)."""
    crud.delete_progress(db, user_firebase_id=uid, lesson_id=lesson_id)
    return None
