from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field, Column
from sqlalchemy import JSON


class Alert(SQLModel, table=True):
    __tablename__ = "alerts"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    monitor_id: Optional[int] = Field(default=None, foreign_key="monitors.id", index=True)
    alert_type: str = Field(index=True)
    severity: str = Field(default="warning")
    title: str
    message: str
    status: str = Field(default="unread", index=True)
    details: dict = Field(default_factory=dict, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None


class AlertRead(SQLModel):
    id: int
    user_id: Optional[int]
    monitor_id: Optional[int]
    alert_type: str
    severity: str
    title: str
    message: str
    status: str
    details: dict
    created_at: datetime
    acknowledged_at: Optional[datetime]
    resolved_at: Optional[datetime]


class AlertUpdate(SQLModel):
    status: Optional[str] = None
