import enum
from sqlalchemy import Column, Integer, String, Float, Enum, ForeignKey, TIMESTAMP, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class ModeEnum(enum.Enum):
    VISIBLE = "VISIBLE"
    BLIND = "BLIND"

class ShadowingResult(Base):
    __tablename__ = "shadowing_results"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer)
    topic_id = Column(Integer, ForeignKey("shadowing_topics.id", ondelete="CASCADE"))
    overall_score = Column(Float)
    detail_scores = Column(JSON, nullable=True)
    user_audio_url = Column(String(255), nullable=True)
    mode = Column(Enum(ModeEnum), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    topic = relationship("ShadowingTopic", back_populates="results")
