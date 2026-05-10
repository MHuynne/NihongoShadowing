from sqlalchemy.orm import Session

from models.vocabulary import Vocabulary
from schemas.vocabulary import VocabularyCreate


def get_vocabularies(
    db: Session,
    skip: int = 0,
    limit: int = 200,
    lesson_id: int | None = None,
    topic_id: int | None = None,
):
    query = db.query(Vocabulary)
    if lesson_id is not None:
        query = query.filter(Vocabulary.lesson_id == lesson_id)
    if topic_id is not None:
        query = query.filter(Vocabulary.topic_id == topic_id)
    return query.offset(skip).limit(limit).all()


def get_vocabulary(db: Session, vocabulary_id: int):
    return db.query(Vocabulary).filter(Vocabulary.id == vocabulary_id).first()


def create_vocabulary(db: Session, vocabulary: VocabularyCreate):
    db_vocabulary = Vocabulary(**vocabulary.model_dump())
    db.add(db_vocabulary)
    db.commit()
    db.refresh(db_vocabulary)
    return db_vocabulary


def update_vocabulary(db: Session, vocabulary_id: int, vocabulary: VocabularyCreate):
    db_vocabulary = get_vocabulary(db, vocabulary_id)
    if db_vocabulary is None:
        return None

    db_vocabulary.lesson_id = vocabulary.lesson_id
    db_vocabulary.topic_id = vocabulary.topic_id
    db_vocabulary.word = vocabulary.word
    db_vocabulary.reading = vocabulary.reading
    db_vocabulary.meaning = vocabulary.meaning
    db_vocabulary.example = vocabulary.example
    db.commit()
    db.refresh(db_vocabulary)
    return db_vocabulary


def delete_vocabulary(db: Session, vocabulary_id: int):
    db_vocabulary = get_vocabulary(db, vocabulary_id)
    if db_vocabulary:
        db.delete(db_vocabulary)
        db.commit()
    return db_vocabulary
