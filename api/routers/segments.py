from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from database import get_db
from models.shadowing_segment import ShadowingSegment
from schemas.shadowing_segment import ShadowingSegmentCreate, ShadowingSegment as SegSchema

router = APIRouter(prefix="/shadowing/segments", tags=["Shadowing Segments"])


@router.get("/all", response_model=List[SegSchema])
def get_all_segments(db: Session = Depends(get_db)):
    """Lấy tất cả segments (kể cả độc lập không thuộc topic), kèm categories."""
    return (
        db.query(ShadowingSegment)
        .options(joinedload(ShadowingSegment.categories))
        .order_by(ShadowingSegment.id)
        .all()
    )


@router.get("/topic/{topic_id}", response_model=List[SegSchema])
def get_by_topic(topic_id: int, db: Session = Depends(get_db)):
    return (
        db.query(ShadowingSegment)
        .options(joinedload(ShadowingSegment.categories))
        .filter(ShadowingSegment.topic_id == topic_id)
        .order_by(ShadowingSegment.order_index)
        .all()
    )


@router.get("/{seg_id}", response_model=SegSchema)
def get_one_segment(seg_id: int, db: Session = Depends(get_db)):
    """Lấy một segment theo id, kèm categories."""
    seg = (
        db.query(ShadowingSegment)
        .options(joinedload(ShadowingSegment.categories))
        .filter(ShadowingSegment.id == seg_id)
        .first()
    )
    if not seg:
        raise HTTPException(404, "Segment not found")
    return seg


@router.post("/standalone", response_model=SegSchema, status_code=status.HTTP_201_CREATED)
def create_standalone(body: ShadowingSegmentCreate, db: Session = Depends(get_db)):
    """Tạo segment độc lập (topic_id có thể null hoặc được chỉ định)."""
    data = body.model_dump()
    seg = ShadowingSegment(**data)
    db.add(seg)
    db.commit()
    db.refresh(seg)
    return seg


@router.post("/", response_model=SegSchema, status_code=status.HTTP_201_CREATED)
def create(topic_id: int, body: ShadowingSegmentCreate, db: Session = Depends(get_db)):
    """Tạo segment gắn vào topic (topic_id bắt buộc qua query param)."""
    seg = ShadowingSegment(**body.model_dump(exclude={"topic_id"}), topic_id=topic_id)
    db.add(seg)
    db.commit()
    db.refresh(seg)
    return seg


@router.put("/{seg_id}", response_model=SegSchema)
def update(seg_id: int, body: ShadowingSegmentCreate, db: Session = Depends(get_db)):
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == seg_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(seg, k, v)
    db.commit()
    db.refresh(seg)
    return seg


@router.delete("/{seg_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(seg_id: int, db: Session = Depends(get_db)):
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == seg_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    db.delete(seg)
    db.commit()
    return None
