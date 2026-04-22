from pydantic import BaseModel
from typing import Optional, List, ForwardRef
from datetime import datetime
from enum import Enum
from .vocabulary import Vocabulary, VocabularyCreate

ShadowingTopicRef = ForwardRef('ShadowingTopic')

class LevelEnum(str, Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class LessonCreate(BaseModel):
    level:        Optional[LevelEnum] = None
    chapter_name: Optional[str] = None
    order_index:  Optional[int] = None
    vocabularies: Optional[List[VocabularyCreate]] = []  # từ vựng cấp chương

class Lesson(LessonCreate):
    id:           int
    created_at:   Optional[datetime] = None
    vocabularies: List[Vocabulary] = []
    shadowing_topics: List[ShadowingTopicRef] = []

    class Config:
        from_attributes = True

from .shadowing_topic import ShadowingTopic
Lesson.model_rebuild()
