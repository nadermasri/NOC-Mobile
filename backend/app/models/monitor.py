from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field, Column
from sqlalchemy import JSON


class Monitor(SQLModel, table=True):
    __tablename__ = "monitors"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id", index=True)
    name: str
    target: str
    monitor_type: str = Field(index=True)
    interval_seconds: int = Field(default=300)
    timeout_seconds: int = Field(default=10)
    retry_count: int = Field(default=3)
    enabled: bool = Field(default=True)
    alert_threshold: int = Field(default=3)

    last_status: str = Field(default="unknown")
    last_checked_at: Optional[datetime] = None
    last_response_ms: Optional[int] = None
    uptime_percentage: float = Field(default=100.0)
    total_checks: int = Field(default=0)
    total_failures: int = Field(default=0)

    config: dict = Field(default_factory=dict, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class MonitorCreate(SQLModel):
    name: str
    target: str
    monitor_type: str
    interval_seconds: int = 300
    timeout_seconds: int = 10
    retry_count: int = 3
    alert_threshold: int = 3
    config: dict = {}


class MonitorUpdate(SQLModel):
    name: Optional[str] = None
    target: Optional[str] = None
    interval_seconds: Optional[int] = None
    timeout_seconds: Optional[int] = None
    retry_count: Optional[int] = None
    alert_threshold: Optional[int] = None
    enabled: Optional[bool] = None
    config: Optional[dict] = None


class MonitorRead(SQLModel):
    id: int
    user_id: Optional[int]
    name: str
    target: str
    monitor_type: str
    interval_seconds: int
    timeout_seconds: int
    retry_count: int
    enabled: bool
    alert_threshold: int
    last_status: str
    last_checked_at: Optional[datetime]
    last_response_ms: Optional[int]
    uptime_percentage: float
    total_checks: int
    total_failures: int
    config: dict
    created_at: datetime


class MonitorExecution(SQLModel, table=True):
    __tablename__ = "monitor_executions"

    id: Optional[int] = Field(default=None, primary_key=True)
    monitor_id: int = Field(foreign_key="monitors.id", index=True)
    status: str
    response_ms: Optional[int] = None
    status_code: Optional[int] = None
    error: Optional[str] = None
    details: dict = Field(default_factory=dict, sa_column=Column(JSON))
    executed_at: datetime = Field(default_factory=datetime.utcnow)


class MonitorExecutionRead(SQLModel):
    id: int
    monitor_id: int
    status: str
    response_ms: Optional[int]
    status_code: Optional[int]
    error: Optional[str]
    details: dict
    executed_at: datetime
