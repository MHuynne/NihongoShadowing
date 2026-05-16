from sqlalchemy import Column, Integer, Text, Float, ForeignKey, Table, String
from sqlalchemy.orm import relationship
from database import Base

# Bảng join nhiều-nhiều: ShadowingSegment <-> Category
# Đặt ở đây để tránh circular import
segment_category_table = Table(
    "segment_categories",
    Base.metadata,
    Column("segment_id", Integer, ForeignKey("shadowing_segments.id", ondelete="CASCADE"), primary_key=True),
    Column("category_id", Integer, ForeignKey("categories.id", ondelete="CASCADE"), primary_key=True),
)


class ShadowingSegment(Base):
    __tablename__ = "shadowing_segments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    topic_id = Column(Integer, ForeignKey("shadowing_topics.id", ondelete="CASCADE"), nullable=True)
    title = Column(String(255), nullable=True)          # Tiêu đề hiển thị
    order_index = Column(Integer)
    start_time = Column(Float)
    end_time = Column(Float)
    kanji_content = Column(Text, nullable=True)
    furigana = Column(Text, nullable=True)
    romaji = Column(Text, nullable=True)
    sino_vietnamese = Column(Text, nullable=True)
    translation_vi = Column(Text, nullable=True)
    image_url = Column(Text, nullable=True)          # Ảnh minh hoạ cho segment

    topic = relationship("ShadowingTopic", back_populates="segments")
    categories = relationship(
        "Category",
        secondary=segment_category_table,
        back_populates="segments",
    )
