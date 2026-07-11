from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from schemas import user_progress as schemas
from crud import user_progress as crud
from models.lesson import Lesson
from models.user_progress import UserProgress as UserProgressModel

router = APIRouter(
    prefix="/progress",
    tags=["User Progress"],
)


def _get_uid(x_firebase_uid: Optional[str] = Header(None)) -> str:
    """Lấy Firebase UID từ header X-Firebase-UID.
    Flutter gửi kèm header này sau khi đăng nhập Firebase.
    """
    if not x_firebase_uid or x_firebase_uid == "null" or x_firebase_uid == "undefined":
        return "mock_user_id"
    return x_firebase_uid



@router.get("/", response_model=List[schemas.UserProgress])
def get_all_progress(
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Lấy tiến độ tất cả lesson của user hiện tại (dùng cho Roadmap Screen)."""
    return crud.get_all_progress(db, user_firebase_id=uid)



@router.get("/summary")
def get_progress_summary(
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """
    Trả về thống kê tổng hợp kết quả học tập của user để hiển thị trên Profile.
    Bao gồm:
    - Số bài hoàn thành, tổng XP, điểm TB Test, điểm TB Shadowing
    - Danh sách chi tiết từng bài học kèm tên bài và kết quả
    """
    progress_list = crud.get_all_progress(db, user_firebase_id=uid)


    lesson_ids = [p.lesson_id for p in progress_list]


    lessons = db.query(Lesson).filter(Lesson.id.in_(lesson_ids)).all()
    lesson_map = {l.id: l for l in lessons}


    total_completed = sum(1 for p in progress_list if p.lesson_completed)
    total_flashcard_done = sum(1 for p in progress_list if p.flashcard_done)

    test_scores = [p.test_score for p in progress_list if p.test_score is not None]
    shadowing_scores = [p.shadowing_score for p in progress_list if p.shadowing_score is not None]

    avg_test_score = round(sum(test_scores) / len(test_scores), 1) if test_scores else 0.0
    avg_shadowing_score = round(sum(shadowing_scores) / len(shadowing_scores), 1) if shadowing_scores else 0.0


    total_xp = 0
    for p in progress_list:
        if p.flashcard_done:
            total_xp += 15
        if p.test_score is not None:
            total_xp += int((p.test_score / 100) * 85)
        if p.shadowing_score is not None:
            total_xp += int((p.shadowing_score / 100) * 85)


    lesson_details = []
    for p in sorted(progress_list, key=lambda x: x.lesson_id):
        lesson = lesson_map.get(p.lesson_id)
        lesson_details.append({
            "lesson_id": p.lesson_id,
            "level": lesson.level.value if lesson and lesson.level else "N5",
            "chapter_name": lesson.chapter_name if lesson else f"Bài {p.lesson_id}",
            "order_index": lesson.order_index if lesson else p.lesson_id,
            "flashcard_done": p.flashcard_done,
            "test_score": p.test_score,
            "test_passed": p.test_passed,
            "shadowing_score": p.shadowing_score,
            "shadowing_passed": p.shadowing_passed,
            "lesson_completed": p.lesson_completed,
            "updated_at": p.updated_at.isoformat() if p.updated_at else None,
        })

    return {
        "total_lessons_started": len(progress_list),
        "total_lessons_completed": total_completed,
        "total_flashcard_done": total_flashcard_done,
        "total_xp": total_xp,
        "avg_test_score": avg_test_score,
        "avg_shadowing_score": avg_shadowing_score,
        "lessons": lesson_details,
    }



@router.get("/{lesson_id}", response_model=schemas.UserProgress)
def get_lesson_progress(
    lesson_id: int,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Lấy tiến độ của user cho 1 lesson cụ thể."""
    record = crud.get_progress(db, user_firebase_id=uid, lesson_id=lesson_id)
    if record is None:

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



@router.delete("/{lesson_id}", status_code=204)
def reset_progress(
    lesson_id: int,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Reset toàn bộ tiến độ của user cho 1 lesson (học lại từ đầu)."""
    crud.delete_progress(db, user_firebase_id=uid, lesson_id=lesson_id)
    return None