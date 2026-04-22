from sqlalchemy import Column, Integer, String, Text, ForeignKey, JSON, DateTime, Enum
from sqlalchemy.orm import relationship
import datetime
from database import Base
import enum

class RoleplayMode(str, enum.Enum):
    keigo = "keigo"
    plain = "plain"

class RoleplayScenario(Base):
    __tablename__ = "roleplay_scenario"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False) # e.g., "Job Interview"
    description = Column(Text) # Instructions/context for AI
    icon_url = Column(String(255))
    
    sessions = relationship("RoleplaySession", back_populates="scenario")

class RoleplaySession(Base):
    __tablename__ = "roleplay_session"
    id = Column(Integer, primary_key=True, index=True)
    scenario_id = Column(Integer, ForeignKey("roleplay_scenario.id"))
    user_id = Column(Integer) # Can be linked to a real user table later
    mode = Column(Enum(RoleplayMode), default=RoleplayMode.keigo)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    scenario = relationship("RoleplayScenario", back_populates="sessions")
    messages = relationship("RoleplayMessage", back_populates="session", cascade="all, delete-orphan")

class RoleplayMessage(Base):
    __tablename__ = "roleplay_message"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("roleplay_session.id"))
    role = Column(String(50)) # "user" or "assistant"
    content = Column(Text) # text content
    grammar_correction = Column(JSON, nullable=True) # AI feedback specific to rule breaks
    suggestions = Column(JSON, nullable=True) # Next sentence suggestions for user
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    session = relationship("RoleplaySession", back_populates="messages")
