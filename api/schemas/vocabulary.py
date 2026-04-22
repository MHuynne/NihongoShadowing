from pydantic import BaseModel
from typing import Optional

class VocabularyBase(BaseModel):
    word: str
    reading: Optional[str] = None
    meaning: str
    example: Optional[str] = None

class VocabularyCreate(VocabularyBase):
    lesson_id: Optional[int] = None  # thuộc lesson (cấp chương)
    topic_id:  Optional[int] = None  # thuộc topic  (cấp tình huống)

class Vocabulary(VocabularyBase):
    id:        int
    lesson_id: Optional[int] = None
    topic_id:  Optional[int] = None

    class Config:
        from_attributes = True
