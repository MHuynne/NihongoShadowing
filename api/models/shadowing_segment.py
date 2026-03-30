from sqlalchemy import Column, Integer, Text, Float, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class ShadowingSegment(Base):
    __tablename__ = "shadowing_segments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("shadowing_topics.id", ondelete="CASCADE"))
    order_index = Column(Integer)
    start_time = Column(Float)
    end_time = Column(Float)
    kanji_content = Column(Text, nullable=True)
    furigana = Column(Text, nullable=True)
    romaji = Column(Text, nullable=True)
    sino_vietnamese = Column(Text, nullable=True)
    translation_vi = Column(Text, nullable=True)

    topic = relationship("ShadowingTopic", back_populates="segments")
