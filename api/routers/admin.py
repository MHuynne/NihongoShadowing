from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends

from database import get_db
from models.lesson import Lesson
from models.roleplay import RoleplayScenario, RoleplaySession
from models.shadowing_result import ShadowingResult
from models.shadowing_topic import ShadowingTopic
from models.vocabulary import Vocabulary


router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/overview")
def get_overview(db: Session = Depends(get_db)):
    lesson_count = db.query(Lesson).count()
    topic_count = db.query(ShadowingTopic).count()
    vocabulary_count = db.query(Vocabulary).count()
    scenario_count = db.query(RoleplayScenario).count()
    session_count = db.query(RoleplaySession).count()
    shadowing_result_count = db.query(ShadowingResult).count()

    latest_lessons = (
        db.query(Lesson).order_by(Lesson.created_at.desc()).limit(5).all()
    )
    latest_topics = (
        db.query(ShadowingTopic).order_by(ShadowingTopic.created_at.desc()).limit(5).all()
    )

    return {
        "counts": {
            "lessons": lesson_count,
            "topics": topic_count,
            "vocabularies": vocabulary_count,
            "scenarios": scenario_count,
            "sessions": session_count,
            "shadowing_results": shadowing_result_count,
        },
        "latest_lessons": [
            {
                "id": lesson.id,
                "chapter_name": lesson.chapter_name,
                "level": lesson.level.value if lesson.level else None,
                "order_index": lesson.order_index,
            }
            for lesson in latest_lessons
        ],
        "latest_topics": [
            {
                "id": topic.id,
                "title": topic.title,
                "level": topic.level.value if topic.level else None,
                "lesson_id": topic.lesson_id,
            }
            for topic in latest_topics
        ],
    }
