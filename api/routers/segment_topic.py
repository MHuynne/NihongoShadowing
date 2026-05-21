from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session, joinedload
from typing import List

from database import get_db
from models.segment_topic import SegmentTopic
from models.category import Category
from models.shadowing_segment import ShadowingSegment
from schemas.segment_topic import SegmentTopicCreate, SegmentTopic as SegTopicSchema
from schemas.shadowing_segment import ShadowingSegment as SegSchema

router = APIRouter(prefix="/segment-topics", tags=["Segment Topics"])


def _load(seg_topic_id: int, db: Session) -> SegmentTopic:
    st = (
        db.query(SegmentTopic)
        .options(
            joinedload(SegmentTopic.categories),
            joinedload(SegmentTopic.segments),
        )
        .filter(SegmentTopic.id == seg_topic_id)
        .first()
    )
    if not st:
        raise HTTPException(404, "SegmentTopic not found")
    return st


@router.get("/", response_model=List[SegTopicSchema])
def get_all(db: Session = Depends(get_db)):
    """Lấy tất cả Segment Topics kèm categories và segments."""
    return (
        db.query(SegmentTopic)
        .options(
            joinedload(SegmentTopic.categories),
            joinedload(SegmentTopic.segments),
        )
        .order_by(SegmentTopic.id)
        .all()
    )


@router.get("/{seg_topic_id}", response_model=SegTopicSchema)
def get_one(seg_topic_id: int, db: Session = Depends(get_db)):
    return _load(seg_topic_id, db)


@router.post("/", response_model=SegTopicSchema, status_code=status.HTTP_201_CREATED)
def create(body: SegmentTopicCreate, db: Session = Depends(get_db)):
    """Tạo mới một Segment Topic."""
    st = SegmentTopic(**body.model_dump())
    db.add(st)
    db.commit()
    db.refresh(st)
    return _load(st.id, db)


@router.put("/{seg_topic_id}", response_model=SegTopicSchema)
def update(seg_topic_id: int, body: SegmentTopicCreate, db: Session = Depends(get_db)):
    """Cập nhật title/description/image của Segment Topic."""
    st = _load(seg_topic_id, db)
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(st, k, v)
    db.commit()
    return _load(seg_topic_id, db)


@router.delete("/{seg_topic_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(seg_topic_id: int, db: Session = Depends(get_db)):
    """Xoá Segment Topic (cascade xoá liên kết segment -> NULL)."""
    st = db.query(SegmentTopic).filter(SegmentTopic.id == seg_topic_id).first()
    if not st:
        raise HTTPException(404, "SegmentTopic not found")
    db.delete(st)
    db.commit()
    return None


# ─── Gán Categories cho SegmentTopic ─────────────────────────────────────────

@router.put("/{seg_topic_id}/set-categories")
def set_categories(
    seg_topic_id: int,
    category_ids: List[int] = Body(..., description="Danh sách category_id cần gán (ghi đè)"),
    db: Session = Depends(get_db),
):
    """Ghi đè toàn bộ categories cho một Segment Topic."""
    st = db.query(SegmentTopic).filter(SegmentTopic.id == seg_topic_id).first()
    if not st:
        raise HTTPException(404, "SegmentTopic not found")
    cats = db.query(Category).filter(Category.id.in_(category_ids)).all() if category_ids else []
    st.categories = cats
    db.commit()
    return {"message": "Categories updated", "count": len(cats)}


# ─── Gán Segments vào SegmentTopic ───────────────────────────────────────────

@router.get("/{seg_topic_id}/segments", response_model=List[SegSchema])
def get_segments(seg_topic_id: int, db: Session = Depends(get_db)):
    """Lấy tất cả segments thuộc một Segment Topic."""
    _load(seg_topic_id, db)   # validate exists
    return (
        db.query(ShadowingSegment)
        .options(joinedload(ShadowingSegment.categories))
        .filter(ShadowingSegment.segment_topic_id == seg_topic_id)
        .order_by(ShadowingSegment.order_index, ShadowingSegment.id)
        .all()
    )


@router.put("/{seg_topic_id}/assign-segment/{seg_id}")
def assign_segment(seg_topic_id: int, seg_id: int, db: Session = Depends(get_db)):
    """Gán một shadowing segment vào segment topic này."""
    _load(seg_topic_id, db)
    seg = db.query(ShadowingSegment).filter(ShadowingSegment.id == seg_id).first()
    if not seg:
        raise HTTPException(404, "Segment not found")
    seg.segment_topic_id = seg_topic_id
    db.commit()
    return {"message": "Assigned"}


@router.put("/{seg_topic_id}/remove-segment/{seg_id}")
def remove_segment(seg_topic_id: int, seg_id: int, db: Session = Depends(get_db)):
    """Gỡ một shadowing segment ra khỏi segment topic (set null)."""
    seg = db.query(ShadowingSegment).filter(
        ShadowingSegment.id == seg_id,
        ShadowingSegment.segment_topic_id == seg_topic_id,
    ).first()
    if not seg:
        raise HTTPException(404, "Segment not found in this topic")
    seg.segment_topic_id = None
    db.commit()
    return {"message": "Removed"}
