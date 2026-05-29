from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class UserProfileBase(BaseModel):
    jlpt_level: Optional[str] = None


class UserProfileUpdate(BaseModel):
    jlpt_level: str


class UserProfile(UserProfileBase):
    user_firebase_id: str
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
