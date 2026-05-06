from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum

class RoleplayMode(str, Enum):
    keigo = "keigo"
    plain = "plain"

class GrammarCorrectionSchema(BaseModel):
    error: str
    correction: str
    explanation: str
    
class RoleplayScenarioBase(BaseModel):
    title: str
    description: Optional[str] = None
    icon_url: Optional[str] = None

class RoleplayScenarioResp(RoleplayScenarioBase):
    id: int
    
    class Config:
        from_attributes = True

class SessionCreateReq(BaseModel):
    scenario_id: int
    user_id: int
    mode: RoleplayMode = RoleplayMode.keigo

class SessionModeUpdateReq(BaseModel):
    mode: RoleplayMode

class SessionResp(BaseModel):
    id: int
    scenario_id: int
    user_id: int
    mode: RoleplayMode
    created_at: datetime
    
    class Config:
        from_attributes = True

class ChatRequestReq(BaseModel):
    session_id: int
    message: str

class ChatResponseResp(BaseModel):
    ai_reply: str
    suggestions: List[str] = []
    grammar_correction: Optional[GrammarCorrectionSchema] = None
    retry_after_seconds: Optional[int] = None

class RoleplayMessageResp(BaseModel):
    id: int
    session_id: int
    role: str
    content: str
    grammar_correction: Optional[GrammarCorrectionSchema] = None
    suggestions: Optional[List[str]] = None
    created_at: datetime

    class Config:
        from_attributes = True

class SessionHistoryResp(BaseModel):
    id: int
    scenario_id: int
    user_id: int
    mode: RoleplayMode
    scenario_title: str
    scenario_description: Optional[str] = None
    message_count: int
    last_message: Optional[str] = None
    last_role: Optional[str] = None
    created_at: datetime
    last_message_at: Optional[datetime] = None

class SessionHistoryDetailResp(BaseModel):
    id: int
    scenario_id: int
    user_id: int
    mode: RoleplayMode
    scenario_title: str
    scenario_description: Optional[str] = None
    created_at: datetime
    messages: List[RoleplayMessageResp] = []
