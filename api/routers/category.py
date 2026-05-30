from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models.category import Category
from models.shadowing_segment import ShadowingSegment
from schemas.category import CategoryCreate, CategoryUpdate
from schemas.category import Category as CategorySchema

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("/", response_model=List[CategorySchema])
def get_all(db: Session = Depends(get_db)):
    return db.query(Category).order_by(Category.id).all()


@router.get("/{category_id}", response_model=CategorySchema)
def get_one(category_id: int, db: Session = Depends(get_db)):
    cat = db.query(Category).filter(Category.id == category_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    return cat


@router.post("/", response_model=CategorySchema, status_code=status.HTTP_201_CREATED)
def create(body: CategoryCreate, db: Session = Depends(get_db)):
    cat = Category(**body.model_dump())
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@router.put("/{category_id}", response_model=CategorySchema)
def update(category_id: int, body: CategoryUpdate, db: Session = Depends(get_db)):
    cat = db.query(Category).filter(Category.id == category_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(cat, k, v)
    db.commit()
    db.refresh(cat)
    return cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(category_id: int, db: Session = Depends(get_db)):
    cat = db.query(Category).filter(Category.id == category_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    db.delete(cat)
    db.commit()
    return None


