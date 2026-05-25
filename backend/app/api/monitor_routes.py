from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select, func

from app.database import get_session
from app.models.monitor import (
    Monitor,
    MonitorCreate,
    MonitorUpdate,
    MonitorRead,
    MonitorExecution,
    MonitorExecutionRead,
)
from app.models.user import User
from app.services.auth import require_user, check_entitlement
from app.services.monitor_executor import execute_monitor

router = APIRouter(prefix="/api/monitors", tags=["monitors"])

VALID_MONITOR_TYPES = {"http", "tcp", "tls", "dns", "ip_change"}


@router.post("/", response_model=MonitorRead, status_code=201)
def create_monitor(
    data: MonitorCreate,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    if data.monitor_type not in VALID_MONITOR_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid monitor type. Must be one of: {', '.join(sorted(VALID_MONITOR_TYPES))}")

    count = session.exec(
        select(func.count()).select_from(Monitor).where(
            Monitor.user_id == user.id, Monitor.enabled == True
        )
    ).one()

    if not check_entitlement(user, "max_monitors", count):
        raise HTTPException(status_code=403, detail="Monitor limit reached for your plan")

    monitor = Monitor(
        user_id=user.id,
        name=data.name.strip()[:100],
        target=data.target.strip()[:253],
        monitor_type=data.monitor_type,
        interval_seconds=max(60, min(data.interval_seconds, 3600)),
        timeout_seconds=max(1, min(data.timeout_seconds, 30)),
        retry_count=max(1, min(data.retry_count, 5)),
        alert_threshold=max(1, min(data.alert_threshold, 10)),
        config=data.config or {},
    )
    session.add(monitor)
    session.commit()
    session.refresh(monitor)
    return MonitorRead.model_validate(monitor)


@router.get("/", response_model=list[MonitorRead])
def list_monitors(
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitors = session.exec(
        select(Monitor)
        .where(Monitor.user_id == user.id)
        .order_by(Monitor.created_at.desc())
    ).all()
    return [MonitorRead.model_validate(m) for m in monitors]


@router.get("/{monitor_id}", response_model=MonitorRead)
def get_monitor(
    monitor_id: int,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitor = session.get(Monitor, monitor_id)
    if not monitor or monitor.user_id != user.id:
        raise HTTPException(status_code=404, detail="Monitor not found")
    return MonitorRead.model_validate(monitor)


@router.put("/{monitor_id}", response_model=MonitorRead)
def update_monitor(
    monitor_id: int,
    data: MonitorUpdate,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitor = session.get(Monitor, monitor_id)
    if not monitor or monitor.user_id != user.id:
        raise HTTPException(status_code=404, detail="Monitor not found")

    if data.name is not None:
        monitor.name = data.name.strip()[:100]
    if data.target is not None:
        monitor.target = data.target.strip()[:253]
    if data.interval_seconds is not None:
        monitor.interval_seconds = max(60, min(data.interval_seconds, 3600))
    if data.timeout_seconds is not None:
        monitor.timeout_seconds = max(1, min(data.timeout_seconds, 30))
    if data.retry_count is not None:
        monitor.retry_count = max(1, min(data.retry_count, 5))
    if data.alert_threshold is not None:
        monitor.alert_threshold = max(1, min(data.alert_threshold, 10))
    if data.enabled is not None:
        monitor.enabled = data.enabled
    if data.config is not None:
        monitor.config = data.config

    session.add(monitor)
    session.commit()
    session.refresh(monitor)
    return MonitorRead.model_validate(monitor)


@router.delete("/{monitor_id}", status_code=204)
def delete_monitor(
    monitor_id: int,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitor = session.get(Monitor, monitor_id)
    if not monitor or monitor.user_id != user.id:
        raise HTTPException(status_code=404, detail="Monitor not found")
    session.delete(monitor)
    session.commit()


@router.post("/{monitor_id}/check", response_model=MonitorExecutionRead)
def run_check_now(
    monitor_id: int,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitor = session.get(Monitor, monitor_id)
    if not monitor or monitor.user_id != user.id:
        raise HTTPException(status_code=404, detail="Monitor not found")
    execution = execute_monitor(monitor, session)
    return MonitorExecutionRead.model_validate(execution)


@router.get("/{monitor_id}/history", response_model=list[MonitorExecutionRead])
def get_history(
    monitor_id: int,
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    monitor = session.get(Monitor, monitor_id)
    if not monitor or monitor.user_id != user.id:
        raise HTTPException(status_code=404, detail="Monitor not found")

    if not check_entitlement(user, "max_history", 0):
        raise HTTPException(status_code=403, detail="History access limited on your plan")

    plan_limit = 50 if user.plan == "free" else limit
    actual_limit = min(limit, plan_limit)

    executions = session.exec(
        select(MonitorExecution)
        .where(MonitorExecution.monitor_id == monitor_id)
        .order_by(MonitorExecution.executed_at.desc())
        .offset(offset)
        .limit(actual_limit)
    ).all()
    return [MonitorExecutionRead.model_validate(e) for e in executions]
