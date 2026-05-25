from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field, Column
from sqlalchemy import JSON


class Report(SQLModel, table=True):
    __tablename__ = "reports"

    id: Optional[int] = Field(default=None, primary_key=True)
    target: str = Field(index=True)
    report_data: dict = Field(sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ReportCreate(SQLModel):
    target: str
    report_data: dict


class ReportRead(SQLModel):
    id: int
    target: str
    report_data: dict
    created_at: datetime
