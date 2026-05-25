from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select, func

from app.database import get_session
from app.models.alert import Alert, AlertRead, AlertUpdate
from app.models.user import User
from app.services.auth import require_user

router = APIRouter(prefix="/api/alerts", tags=["alerts"])


@router.get("/", response_model=list[AlertRead])
def list_alerts(
    status: str = Query(default=None),
    severity: str = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    query = select(Alert).where(Alert.user_id == user.id)
    if status:
        query = query.where(Alert.status == status)
    if severity:
        query = query.where(Alert.severity == severity)
    query = query.order_by(Alert.created_at.desc()).offset(offset).limit(limit)
    alerts = session.exec(query).all()
    return [AlertRead.model_validate(a) for a in alerts]


@router.get("/unread-count")
def unread_count(
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    count = session.exec(
        select(func.count()).select_from(Alert).where(
            Alert.user_id == user.id, Alert.status == "unread"
        )
    ).one()
    return {"count": count}


@router.get("/{alert_id}", response_model=AlertRead)
def get_alert(
    alert_id: int,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    alert = session.get(Alert, alert_id)
    if not alert or alert.user_id != user.id:
        raise HTTPException(status_code=404, detail="Alert not found")
    return AlertRead.model_validate(alert)


@router.put("/{alert_id}", response_model=AlertRead)
def update_alert(
    alert_id: int,
    data: AlertUpdate,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    alert = session.get(Alert, alert_id)
    if not alert or alert.user_id != user.id:
        raise HTTPException(status_code=404, detail="Alert not found")

    if data.status is not None:
        valid = {"unread", "acknowledged", "resolved"}
        if data.status not in valid:
            raise HTTPException(status_code=400, detail=f"Status must be one of: {', '.join(sorted(valid))}")
        alert.status = data.status
        if data.status == "acknowledged":
            alert.acknowledged_at = datetime.utcnow()
        elif data.status == "resolved":
            alert.resolved_at = datetime.utcnow()

    session.add(alert)
    session.commit()
    session.refresh(alert)
    return AlertRead.model_validate(alert)


@router.post("/acknowledge-all", status_code=200)
def acknowledge_all(
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    alerts = session.exec(
        select(Alert).where(Alert.user_id == user.id, Alert.status == "unread")
    ).all()
    now = datetime.utcnow()
    for alert in alerts:
        alert.status = "acknowledged"
        alert.acknowledged_at = now
        session.add(alert)
    session.commit()
    return {"acknowledged": len(alerts)}
