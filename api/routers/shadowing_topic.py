from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas import shadowing_topic as schemas
from schemas import vocabulary as vocab_schemas
from crud import shadowing_topic as crud
from models.vocabulary import Vocabulary as VocabularyModel

router = APIRouter(
    prefix="/shadowing/topics",
    tags=["Shadowing Topics"]
)


@router.get("/", response_model=List[schemas.ShadowingTopic])
def read_topics(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Lấy danh sách các chủ đề Shadowing, bao gồm mảng segments."""
    return crud.get_topics(db, skip=skip, limit=limit)


@router.get("/{topic_id}", response_model=schemas.ShadowingTopic)
def read_topic(topic_id: int, db: Session = Depends(get_db)):
    """Lấy chi tiết 1 chủ đề Shadowing bằng ID."""
    db_topic = crud.get_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return db_topic


@router.get("/{topic_id}/vocabulary", response_model=List[vocab_schemas.Vocabulary])
def get_topic_vocabulary(
    topic_id: int,
    limit: int = 40,
    db: Session = Depends(get_db),
):
    """
    Lấy danh sách từ vựng (tối đa 40 từ) của 1 Shadowing Topic.
    Dùng cho màn hình Vocabulary Discovery sau khi hoàn thành bài shadowing.
    """
    db_topic = crud.get_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")

    vocabs = (
        db.query(VocabularyModel)
        .filter(VocabularyModel.topic_id == topic_id)
        .limit(limit)
        .all()
    )
    return vocabs


@router.post("/", response_model=schemas.ShadowingTopic, status_code=status.HTTP_201_CREATED)
def create_topic(topic: schemas.ShadowingTopicCreate, db: Session = Depends(get_db)):
    """Tạo mới 1 chủ đề."""
    return crud.create_topic(db=db, topic=topic)


@router.delete("/{topic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_topic(topic_id: int, db: Session = Depends(get_db)):
    """Xóa 1 chủ đề Shadowing (cascade xóa segments và kết quả)."""
    db_topic = crud.delete_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return None
