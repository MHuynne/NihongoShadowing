from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import Optional

from database import get_db
from schemas import user_profile as schemas
from crud import user_profile as crud

router = APIRouter(
    prefix="/profile",
    tags=["User Profile"],
)


def _get_uid(x_firebase_uid: Optional[str] = Header(None)) -> str:
    """Lấy Firebase UID từ header X-Firebase-UID.
    Flutter gửi kèm header này sau khi đăng nhập Firebase.
    """
    if not x_firebase_uid or x_firebase_uid == "null" or x_firebase_uid == "undefined":
        return "mock_user_id"
    return x_firebase_uid


@router.get("/", response_model=schemas.UserProfile)
def get_user_profile(
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Lấy thông tin profile người dùng bao gồm cấp độ JLPT đã chọn."""
    profile = crud.get_profile(db, user_firebase_id=uid)
    if profile is None:

        return schemas.UserProfile(user_firebase_id=uid, jlpt_level=None)
    return profile


@router.put("/level", response_model=schemas.UserProfile)
def update_user_level(
    body: schemas.UserProfileUpdate,
    uid: str = Depends(_get_uid),
    db: Session = Depends(get_db),
):
    """Cập nhật hoặc đặt mới cấp độ JLPT cho user trong database."""
    return crud.upsert_profile_level(db, user_firebase_id=uid, jlpt_level=body.jlpt_level)