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
