from sqlalchemy import Column, Integer, String, Boolean, Float, TIMESTAMP, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class UserProgress(Base):
    __tablename__ = "user_progress"

    id                  = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_firebase_id    = Column(String(128), nullable=False, index=True)  # Firebase UID
    lesson_id           = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False)

    # ── Bước 1: Flashcard ────────────────────────────────────────────────
    flashcard_done      = Column(Boolean, default=False, nullable=False)

    # ── Bước 2: Vocabulary Test ──────────────────────────────────────────
    test_score          = Column(Float, nullable=True)    # 0–100, NULL = chưa làm
    test_passed         = Column(Boolean, default=False, nullable=False)   # >= 70

    # ── Bước 3: Shadowing ────────────────────────────────────────────────
    shadowing_score     = Column(Float, nullable=True)    # 0–100, NULL = chưa làm
    shadowing_passed    = Column(Boolean, default=False, nullable=False)   # >= 80

    # ── Tổng ─────────────────────────────────────────────────────────────
    lesson_completed    = Column(Boolean, default=False, nullable=False)

    updated_at          = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    # Unique: 1 user chỉ có 1 bản ghi tiến độ per lesson
    __table_args__ = (
        UniqueConstraint("user_firebase_id", "lesson_id", name="uq_user_lesson"),
    )

    lesson = relationship("Lesson")
