import enum
from sqlalchemy import Column, Integer, String, Enum, TIMESTAMP
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class LevelEnum(enum.Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    level = Column(Enum(LevelEnum), nullable=True)
    chapter_name = Column(String(255), nullable=True)
    order_index = Column(Integer, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    shadowing_topics = relationship("ShadowingTopic", back_populates="lesson")
