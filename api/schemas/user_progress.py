from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class UserProgressBase(BaseModel):
    lesson_id:          int
    flashcard_done:     bool  = False
    test_score:         Optional[float] = None
    test_passed:        bool  = False
    shadowing_score:    Optional[float] = None
    shadowing_passed:   bool  = False
    lesson_completed:   bool  = False


class UserProgressUpdate(BaseModel):
    """Dùng để PATCH — chỉ gửi field cần cập nhật."""
    flashcard_done:     Optional[bool]  = None
    test_score:         Optional[float] = None
    test_passed:        Optional[bool]  = None
    shadowing_score:    Optional[float] = None
    shadowing_passed:   Optional[bool]  = None
    lesson_completed:   Optional[bool]  = None


class UserProgressCreate(UserProgressBase):
    pass


class UserProgress(UserProgressBase):
    id:                 int
    user_firebase_id:   str
    updated_at:         Optional[datetime] = None

    class Config:
        from_attributes = True
