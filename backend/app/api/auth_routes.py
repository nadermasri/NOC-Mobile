import re
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.user import User, UserCreate, UserLogin, UserRead, TokenResponse
from app.services.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    require_user,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])

_EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")


@router.post("/signup", response_model=TokenResponse, status_code=201)
def signup(data: UserCreate, session: Session = Depends(get_session)):
    if not data.email or not data.password:
        raise HTTPException(status_code=400, detail="Email and password required")
    if not _EMAIL_RE.match(data.email):
        raise HTTPException(status_code=400, detail="Invalid email format")
    if len(data.password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters")
    if len(data.password) > 128:
        raise HTTPException(status_code=400, detail="Password too long")

    existing = session.exec(select(User).where(User.email == data.email.lower())).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        email=data.email.lower().strip(),
        hashed_password=hash_password(data.password),
        display_name=data.display_name.strip()[:100] if data.display_name else "",
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user=UserRead.model_validate(user),
    )


@router.post("/login", response_model=TokenResponse)
def login(data: UserLogin, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.email == data.email.lower())).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account disabled")

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user=UserRead.model_validate(user),
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(token: str, session: Session = Depends(get_session)):
    payload = decode_token(token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    user = session.get(User, int(payload["sub"]))
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid user")

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user=UserRead.model_validate(user),
    )


@router.get("/me", response_model=UserRead)
def get_me(user: User = Depends(require_user)):
    return UserRead.model_validate(user)


@router.put("/me", response_model=UserRead)
def update_me(
    display_name: str = None,
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    if display_name is not None:
        user.display_name = display_name.strip()[:100]
    user.updated_at = datetime.utcnow()
    session.add(user)
    session.commit()
    session.refresh(user)
    return UserRead.model_validate(user)


@router.delete("/me", status_code=204)
def delete_account(
    user: User = Depends(require_user),
    session: Session = Depends(get_session),
):
    user.is_active = False
    user.updated_at = datetime.utcnow()
    session.add(user)
    session.commit()
