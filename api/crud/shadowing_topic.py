from sqlalchemy.orm import Session
from models.shadowing_topic import ShadowingTopic
from models.shadowing_segment import ShadowingSegment
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
        total_duration=topic.total_duration
    )
    db.add(db_topic)
    db.commit()
    db.refresh(db_topic)
    
    if topic.segments:
        for seg in topic.segments:
            db_seg = ShadowingSegment(**seg.model_dump(), topic_id=db_topic.id)
            db.add(db_seg)
        db.commit()
        db.refresh(db_topic)
        
    return db_topic

def delete_topic(db: Session, topic_id: int):
    db_topic = get_topic(db, topic_id)
    if db_topic:
        db.delete(db_topic)
        db.commit()
    return db_topic
