from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from crud import shadowing_topic as crud
from database import get_db
from schemas import shadowing_topic as schemas


router = APIRouter(prefix="/shadowing/topics", tags=["Shadowing Topics"])


@router.get("/", response_model=List[schemas.ShadowingTopic])
def read_topics(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_topics(db, skip=skip, limit=limit)


@router.get("/{topic_id}", response_model=schemas.ShadowingTopic)
def read_topic(topic_id: int, db: Session = Depends(get_db)):
    db_topic = crud.get_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return db_topic


@router.post("/", response_model=schemas.ShadowingTopic, status_code=status.HTTP_201_CREATED)
def create_topic(topic: schemas.ShadowingTopicCreate, db: Session = Depends(get_db)):
    return crud.create_topic(db=db, topic=topic)


@router.put("/{topic_id}", response_model=schemas.ShadowingTopic)
def update_topic(topic_id: int, topic: schemas.ShadowingTopicCreate, db: Session = Depends(get_db)):
    db_topic = crud.update_topic(db, topic_id=topic_id, topic=topic)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return db_topic


@router.delete("/{topic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_topic(topic_id: int, db: Session = Depends(get_db)):
    db_topic = crud.delete_topic(db, topic_id=topic_id)
    if db_topic is None:
        raise HTTPException(status_code=404, detail="Topic not found")
    return None
