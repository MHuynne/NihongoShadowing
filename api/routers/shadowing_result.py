from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from schemas import shadowing_result as schemas
from crud import shadowing_result as crud

router = APIRouter(
    prefix="/shadowing/results",
    tags=["Shadowing Results"]
)

@router.post("/", response_model=schemas.ShadowingResult, status_code=status.HTTP_201_CREATED)
def submit_result(result: schemas.ShadowingResultCreate, db: Session = Depends(get_db)):
    """Người dùng nộp kết quả bài học Shadowing"""
    return crud.create_result(db=db, result=result)

@router.get("/user/{user_id}", response_model=List[schemas.ShadowingResult])
def read_user_results(user_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Lấy danh sách các kết quả Shadowing của một User"""
    return crud.get_results_by_user(db, user_id=user_id, skip=skip, limit=limit)
