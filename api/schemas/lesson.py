from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class LevelEnum(str, Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class LessonCreate(BaseModel):
    level: Optional[LevelEnum] = None
    chapter_name: Optional[str] = None
    order_index: Optional[int] = None

class Lesson(LessonCreate):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
