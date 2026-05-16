from pydantic import BaseModel
from typing import Optional, List

class CategorySimple(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True

class ShadowingSegmentBase(BaseModel):
    title: Optional[str] = None           # Tiêu đề hiển thị
    order_index: int
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    kanji_content: Optional[str] = None
    furigana: Optional[str] = None
    romaji: Optional[str] = None
    sino_vietnamese: Optional[str] = None
    translation_vi: Optional[str] = None
    image_url: Optional[str] = None

class ShadowingSegmentCreate(ShadowingSegmentBase):
    topic_id: Optional[int] = None  # Cho phép tạo segment độc lập

class ShadowingSegment(ShadowingSegmentBase):
    id: int
    topic_id: Optional[int] = None
    categories: List[CategorySimple] = []

    class Config:
        from_attributes = True
