from pydantic import BaseModel
from typing import Optional

class ShadowingSegmentBase(BaseModel):
    order_index: int
    start_time: float
    end_time: float
    kanji_content: Optional[str] = None
    furigana: Optional[str] = None
    romaji: Optional[str] = None
    sino_vietnamese: Optional[str] = None
    translation_vi: Optional[str] = None

class ShadowingSegmentCreate(ShadowingSegmentBase):
    pass

class ShadowingSegment(ShadowingSegmentBase):
    id: int
    topic_id: int

    class Config:
        from_attributes = True
