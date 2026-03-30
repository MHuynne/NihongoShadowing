from sqlalchemy.orm import Session
from models.lesson import Lesson
from schemas.lesson import LessonCreate

def get_lessons(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Lesson).offset(skip).limit(limit).all()

def get_lesson(db: Session, lesson_id: int):
    return db.query(Lesson).filter(Lesson.id == lesson_id).first()

def create_lesson(db: Session, lesson: LessonCreate):
    db_lesson = Lesson(
        level=lesson.level.value if lesson.level else None,
        chapter_name=lesson.chapter_name,
        order_index=lesson.order_index
    )
    db.add(db_lesson)
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

def delete_lesson(db: Session, lesson_id: int):
    db_lesson = get_lesson(db, lesson_id)
    if db_lesson:
        db.delete(db_lesson)
        db.commit()
    return db_lesson
