from sqlalchemy import Column, Integer, String, Boolean, Float, TIMESTAMP, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class UserProgress(Base):
    __tablename__ = "user_progress"

    id                  = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_firebase_id    = Column(String(128), nullable=False, index=True)
    lesson_id           = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False)


    flashcard_done      = Column(Boolean, default=False, nullable=False)


    test_score          = Column(Float, nullable=True)
    test_passed         = Column(Boolean, default=False, nullable=False)


    shadowing_score     = Column(Float, nullable=True)
    shadowing_passed    = Column(Boolean, default=False, nullable=False)


    lesson_completed    = Column(Boolean, default=False, nullable=False)

    updated_at          = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


    __table_args__ = (
        UniqueConstraint("user_firebase_id", "lesson_id", name="uq_user_lesson"),
    )

    lesson = relationship("Lesson")