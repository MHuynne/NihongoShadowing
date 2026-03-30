from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime
from enum import Enum

class ModeEnum(str, Enum):
    VISIBLE = "VISIBLE"
    BLIND = "BLIND"

class ShadowingResultBase(BaseModel):
    user_id: int
    topic_id: int
    overall_score: Optional[float] = None
    detail_scores: Optional[Dict[str, float]] = None
    user_audio_url: Optional[str] = None
    mode: Optional[ModeEnum] = None

class ShadowingResultCreate(ShadowingResultBase):
    pass

class ShadowingResult(ShadowingResultBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
