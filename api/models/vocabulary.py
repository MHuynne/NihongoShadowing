from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id       = Column(Integer, primary_key=True, index=True, autoincrement=True)
    # Vocabulary thuộc lesson (cấp chương) và/hoặc topic (cấp tình huống)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True)
    topic_id  = Column(Integer, ForeignKey("shadowing_topics.id", ondelete="CASCADE"), nullable=True)
    word      = Column(String(255), nullable=False)  # Từ vựng chính (Kanji/Kana)
    reading   = Column(String(255), nullable=True)   # Cách phát âm (Hiragana/Romaji)
    meaning   = Column(String(255), nullable=False)  # Nghĩa tiếng Việt
    example   = Column(Text, nullable=True)          # Câu ví dụ

    lesson = relationship("Lesson", back_populates="vocabularies")
    topic  = relationship("ShadowingTopic", back_populates="vocabularies")
