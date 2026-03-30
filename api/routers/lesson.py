from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas import lesson as schemas
from crud import lesson as crud

router = APIRouter(
    prefix="/lessons",
    tags=["Lessons"]
)

@router.get("/", response_model=List[schemas.Lesson])
def read_lessons(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Lấy danh sách các bài học"""
    return crud.get_lessons(db, skip=skip, limit=limit)

@router.get("/{lesson_id}", response_model=schemas.Lesson)
def read_lesson(lesson_id: int, db: Session = Depends(get_db)):
    """Lấy chi tiết 1 bài học"""
    db_lesson = crud.get_lesson(db, lesson_id=lesson_id)
    if db_lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return db_lesson

@router.post("/", response_model=schemas.Lesson, status_code=status.HTTP_201_CREATED)
def create_lesson(lesson: schemas.LessonCreate, db: Session = Depends(get_db)):
    """Tạo mới 1 bài học"""
    return crud.create_lesson(db=db, lesson=lesson)

@router.delete("/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_lesson(lesson_id: int, db: Session = Depends(get_db)):
    """Xóa 1 bài học"""
    db_lesson = crud.delete_lesson(db, lesson_id=lesson_id)
    if db_lesson is None:
        raise HTTPException(status_code=404, detail="Lesson not found")
    return None
