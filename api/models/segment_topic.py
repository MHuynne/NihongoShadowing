import enum
from sqlalchemy import Column, Integer, String, Text, Table, ForeignKey, Enum
from sqlalchemy.orm import relationship
from database import Base


segment_topic_category_table = Table(
    "segment_topic_categories",
    Base.metadata,
    Column(
        "segment_topic_id",
        Integer,
        ForeignKey("segment_topics.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "category_id",
        Integer,
        ForeignKey("categories.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


class LevelEnum(enum.Enum):
    N5 = "N5"
    N4 = "N4"
    N3 = "N3"
    N2 = "N2"
    N1 = "N1"


class SegmentTopic(Base):
    __tablename__ = "segment_topics"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(Text, nullable=True)
    level = Column(Enum(LevelEnum), nullable=True)


    categories = relationship(
        "Category",
        secondary=segment_topic_category_table,
        back_populates="segment_topics",
    )


    segments = relationship(
        "ShadowingSegment",
        back_populates="segment_topic",
        cascade="all, delete-orphan",
    )