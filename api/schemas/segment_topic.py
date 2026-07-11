from pydantic import BaseModel
from typing import Optional, List


class CategorySimple(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class SegmentSimple(BaseModel):
    """Thông tin tóm gọn của segment (dùng trong response của SegmentTopic)."""
    id: int
    title: Optional[str] = None
    kanji_content: Optional[str] = None
    furigana: Optional[str] = None
    translation_vi: Optional[str] = None
    order_index: int = 1

    class Config:
        from_attributes = True


class SegmentTopicBase(BaseModel):
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    level: Optional[str] = None


class SegmentTopicCreate(SegmentTopicBase):
    pass


class SegmentTopic(SegmentTopicBase):
    id: int
    categories: List[CategorySimple] = []
    segments: List[SegmentSimple] = []

    class Config:
        from_attributes = True