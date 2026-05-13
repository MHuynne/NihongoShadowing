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


# ─── Gán / gỡ categories khỏi segment ───────────────────────────────────────

@router.post("/segment/{segment_id}/assign")
def assign_category_to_segment(
    segment_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    """Gán một category vào segment."""
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == segment_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    cat = db.query(Category).filter(Category.id == category_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    if cat not in seg.categories:
        seg.categories.append(cat)
        db.commit()
    return {"message": "Assigned"}


@router.delete("/segment/{segment_id}/remove")
def remove_category_from_segment(
    segment_id: int,
    category_id: int,
    db: Session = Depends(get_db),
):
    """Gỡ một category khỏi segment."""
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == segment_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    cat = db.query(Category).filter(Category.id == category_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    if cat in seg.categories:
        seg.categories.remove(cat)
        db.commit()
    return {"message": "Removed"}


@router.put("/segment/{segment_id}/set-categories")
def set_segment_categories(
    segment_id: int,
    category_ids: List[int] = Body(..., description="Danh sach category_id can gan (ghi de hoan toan)"),
    db: Session = Depends(get_db),
):
    """Gán hàng loạt categories cho segment (ghi đè hoàn toàn)."""
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == segment_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    if not category_ids:
        seg.categories = []
        db.commit()
        return {"message": "Categories cleared", "count": 0}
    cats = db.query(Category).filter(Category.id.in_(category_ids)).all()
    seg.categories = cats
    db.commit()
    return {"message": "Categories updated", "count": len(cats)}
