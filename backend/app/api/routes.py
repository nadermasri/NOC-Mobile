import re
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, field_validator
from sqlmodel import Session, select
from app.database import get_session
from app.models.report import Report, ReportCreate, ReportRead
from app.services.ai_explain import explain_diagnostic

router = APIRouter(prefix="/api")

_SAFE_TEXT = re.compile(r'^[\w\s.\-:/\[\]{}(),@#%&*+=!?\'"<>]+$')
MAX_PAYLOAD_SIZE = 50_000


def _sanitize(value: str) -> str:
    return value[:500].strip()


class ExplainRequest(BaseModel):
    type: str
    target: str
    result: dict

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        allowed = {"ping", "dns", "port", "tls", "http", "traceroute", "reverseDns", "subnet"}
        v = v.strip()
        if v not in allowed:
            raise ValueError(f"Invalid diagnostic type: {v}")
        return v

    @field_validator("target")
    @classmethod
    def validate_target(cls, v: str) -> str:
        v = v.strip()
        if len(v) > 253:
            raise ValueError("Target too long")
        if not v:
            raise ValueError("Target is required")
        return _sanitize(v)


@router.get("/health")
async def health_check():
    return {"status": "ok", "service": "pocket-noc-api"}


@router.post("/ai/explain")
async def ai_explain(data: ExplainRequest):
    result = explain_diagnostic(data.model_dump())
    return result


@router.post("/reports/save", response_model=ReportRead)
async def save_report(report: ReportCreate, session: Session = Depends(get_session)):
    if len(str(report.report_data)) > MAX_PAYLOAD_SIZE:
        raise HTTPException(status_code=413, detail="Report data too large")

    db_report = Report(
        target=_sanitize(report.target),
        report_data=report.report_data,
    )
    session.add(db_report)
    session.commit()
    session.refresh(db_report)
    return db_report


@router.get("/reports", response_model=list[ReportRead])
async def get_reports(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: Session = Depends(get_session),
):
    statement = (
        select(Report)
        .order_by(Report.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    reports = session.exec(statement).all()
    return reports
