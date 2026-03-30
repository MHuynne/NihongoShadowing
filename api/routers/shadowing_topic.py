from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas import shadowing_topic as schemas
from crud import shadowing_topic as crud

router = APIRouter(
    prefix="/shadowing/topics",
    tags=["Shadowing Topics"]
)

@router.get("/", response_model=List[schemas.ShadowingTopic])
def read_topics(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Lấy danh sách các chủ đề Shadowing, bao gồm mảng segments chứa từng câu."""
    return crud.get_topics(db, skip=skip, limit=limit)

@router.get("/{topic_id}", response_model=schemas.ShadowingTopic)
def read_topic(topic_id: int, db: Session = Depends(get_db)):
    """Lấy chi tiết 1 chủ đề Shadowing bằng ID"""
    db_topic = crud.get_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return db_topic

@router.post("/", response_model=schemas.ShadowingTopic, status_code=status.HTTP_201_CREATED)
def create_topic(topic: schemas.ShadowingTopicCreate, db: Session = Depends(get_db)):
    """Tạo mới 1 chủ đề (có thể tạo tự động luôn các list segments bên trong body)"""
    return crud.create_topic(db=db, topic=topic)

@router.delete("/{topic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_topic(topic_id: int, db: Session = Depends(get_db)):
    """Xóa 1 chủ đề Shadowing (tự động xóa cascade các segments và kết quả theo constraint foreign key)"""
    db_topic = crud.delete_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return None
