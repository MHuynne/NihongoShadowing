from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True)       # vd: "Giao tiếp", "Du lịch", "Công việc"
    description = Column(String(255), nullable=True)

    # Sử dụng string reference và lazy import để tránh circular import
    segments = relationship(
        "ShadowingSegment",
        secondary="segment_categories",   # tên bảng (string) – SQLAlchemy tự resolve
        back_populates="categories",
    )
