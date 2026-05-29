from sqlalchemy import Column, String, TIMESTAMP
from sqlalchemy.sql import func
from database import Base

class UserProfile(Base):
    __tablename__ = "user_profiles"

    user_firebase_id = Column(String(128), primary_key=True, index=True)
    jlpt_level       = Column(String(10), nullable=True)  # e.g., 'N5', 'N4', 'N3', 'N2', 'N1'
    updated_at       = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
