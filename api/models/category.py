from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True)       # vd: "Giao tiếp", "Du lịch", "Công việc"
    description = Column(String(255), nullable=True)

    # Many-to-many với SegmentTopic
    segment_topics = relationship(
        "SegmentTopic",
        secondary="segment_topic_categories",
        back_populates="categories",
    )
