from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from crud import vocabulary as crud
from database import get_db
from schemas import vocabulary as schemas


router = APIRouter(prefix="/vocabularies", tags=["Vocabularies"])


@router.get("/", response_model=List[schemas.Vocabulary])
def read_vocabularies(
    skip: int = 0,
    limit: int = 200,
    lesson_id: Optional[int] = Query(None),
    topic_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    return crud.get_vocabularies(
        db,
        skip=skip,
        limit=limit,
        lesson_id=lesson_id,
        topic_id=topic_id,
    )


@router.get("/{vocabulary_id}", response_model=schemas.Vocabulary)
def read_vocabulary(vocabulary_id: int, db: Session = Depends(get_db)):
    db_vocabulary = crud.get_vocabulary(db, vocabulary_id)
    if db_vocabulary is None:
        raise HTTPException(status_code=404, detail="Vocabulary not found")
    return db_vocabulary


@router.post("/", response_model=schemas.Vocabulary, status_code=status.HTTP_201_CREATED)
def create_vocabulary(vocabulary: schemas.VocabularyCreate, db: Session = Depends(get_db)):
    return crud.create_vocabulary(db, vocabulary)


@router.put("/{vocabulary_id}", response_model=schemas.Vocabulary)
def update_vocabulary(
    vocabulary_id: int,
    vocabulary: schemas.VocabularyCreate,
    db: Session = Depends(get_db),
):
    db_vocabulary = crud.update_vocabulary(db, vocabulary_id, vocabulary)
    if db_vocabulary is None:
        raise HTTPException(status_code=404, detail="Vocabulary not found")
    return db_vocabulary


@router.delete("/{vocabulary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vocabulary(vocabulary_id: int, db: Session = Depends(get_db)):
    db_vocabulary = crud.delete_vocabulary(db, vocabulary_id)
    if db_vocabulary is None:
        raise HTTPException(status_code=404, detail="Vocabulary not found")
    return None
