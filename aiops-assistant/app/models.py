from typing import Any

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    session_id: str = Field(..., min_length=3)
    message: str = Field(..., min_length=3)
    routing_mode: str = Field(default="auto")
    max_tool_rounds: int = Field(default=3, ge=1, le=6)


class AlertTriageRequest(BaseModel):
    session_id: str = Field(..., min_length=3)
    alert_name: str
    service: str
    summary: str
    signal_hint: str = ""


class RetrievedDocument(BaseModel):
    title: str
    source: str
    category: str
    score: float


class ChatResponse(BaseModel):
    session_id: str
    model: str
    answer: str
    confidence: str
    tools_used: list[str]
    retrieved_documents: list[RetrievedDocument]
    dashboard_links: dict[str, str]


class SessionSnapshot(BaseModel):
    session_id: str
    history: list[dict[str, Any]]

