from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum
from .shadowing_segment import ShadowingSegmentCreate, ShadowingSegment
from .vocabulary import VocabularyCreate, Vocabulary

class LevelEnum(str, Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class ShadowingTopicBase(BaseModel):
    title: str
    level: Optional[LevelEnum] = None
    lesson_id: Optional[int] = None
    image_url: Optional[str] = None
    full_audio_url: Optional[str] = None
    full_script_ja: Optional[str] = None
    total_duration: Optional[float] = None

class ShadowingTopicCreate(ShadowingTopicBase):
    segments: Optional[List[ShadowingSegmentCreate]] = []
    vocabularies: Optional[List[VocabularyCreate]] = []

class ShadowingTopic(ShadowingTopicBase):
    id: int
    created_at: Optional[datetime] = None
    segments: List[ShadowingSegment] = []
    vocabularies: List[Vocabulary] = []

    class Config:
        from_attributes = True
