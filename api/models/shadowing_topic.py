import enum
from sqlalchemy import Column, Integer, String, Text, Float, Enum, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class LevelEnum(enum.Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"

class ShadowingTopic(Base):
    __tablename__ = "shadowing_topics"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    level = Column(Enum(LevelEnum), nullable=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=True)
    image_url = Column(String(255), nullable=True)
    full_audio_url = Column(String(255), nullable=True)
    full_script_ja = Column(Text, nullable=True)
    total_duration = Column(Float, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    lesson = relationship("Lesson", back_populates="shadowing_topics")
    segments = relationship("ShadowingSegment", back_populates="topic", cascade="all, delete-orphan")
    results = relationship("ShadowingResult", back_populates="topic", cascade="all, delete-orphan")
    vocabularies = relationship("Vocabulary", back_populates="topic", cascade="all, delete-orphan")
