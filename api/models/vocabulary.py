from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id       = Column(Integer, primary_key=True, index=True, autoincrement=True)

    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True)
    topic_id  = Column(Integer, ForeignKey("shadowing_topics.id", ondelete="CASCADE"), nullable=True)
    word      = Column(String(255), nullable=False)
    reading   = Column(String(255), nullable=True)
    meaning   = Column(String(255), nullable=False)
    example   = Column(Text, nullable=True)

    lesson = relationship("Lesson", back_populates="vocabularies")
    topic  = relationship("ShadowingTopic", back_populates="vocabularies")