from sqlalchemy.orm import Session

from models.shadowing_segment import ShadowingSegment
from models.shadowing_topic import ShadowingTopic
from models.vocabulary import Vocabulary
from schemas.shadowing_topic import ShadowingTopicCreate


def get_topics(db: Session, skip: int = 0, limit: int = 100):
    return db.query(ShadowingTopic).offset(skip).limit(limit).all()


def get_topic(db: Session, topic_id: int):
    return db.query(ShadowingTopic).filter(ShadowingTopic.id == topic_id).first()


def create_topic(db: Session, topic: ShadowingTopicCreate):
    db_topic = ShadowingTopic(
        title=topic.title,
        level=topic.level.value if topic.level else None,
        lesson_id=topic.lesson_id,
        image_url=topic.image_url,
        full_audio_url=topic.full_audio_url,
        full_script_ja=topic.full_script_ja,
        total_duration=topic.total_duration,
    )
    db.add(db_topic)
    db.commit()
    db.refresh(db_topic)

    if topic.segments:
        for seg in topic.segments:
            db.add(ShadowingSegment(**seg.model_dump(), topic_id=db_topic.id))

    if topic.vocabularies:
        for vocab in topic.vocabularies:
            db.add(Vocabulary(**vocab.model_dump(), topic_id=db_topic.id))

    db.commit()
    db.refresh(db_topic)
    return db_topic


def update_topic(db: Session, topic_id: int, topic: ShadowingTopicCreate):
    db_topic = get_topic(db, topic_id)
    if db_topic is None:
        return None

    db_topic.title = topic.title
    db_topic.level = topic.level.value if topic.level else None
    db_topic.lesson_id = topic.lesson_id
    db_topic.image_url = topic.image_url
    db_topic.full_audio_url = topic.full_audio_url
    db_topic.full_script_ja = topic.full_script_ja
    db_topic.total_duration = topic.total_duration

    db.query(ShadowingSegment).filter(
        ShadowingSegment.topic_id == topic_id
    ).delete(synchronize_session=False)
    db.query(Vocabulary).filter(
        Vocabulary.topic_id == topic_id
    ).delete(synchronize_session=False)
    db.flush()

    if topic.segments:
        for seg in topic.segments:
            db.add(ShadowingSegment(**seg.model_dump(), topic_id=topic_id))

    if topic.vocabularies:
        for vocab in topic.vocabularies:
            db.add(Vocabulary(**vocab.model_dump(), topic_id=topic_id))

    db.commit()
    db.refresh(db_topic)
    return db_topic


def delete_topic(db: Session, topic_id: int):
    db_topic = get_topic(db, topic_id)
    if db_topic:
        db.delete(db_topic)
        db.commit()
    return db_topic
