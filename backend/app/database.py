import logging
from sqlmodel import SQLModel, create_engine, Session
from app.config import DATABASE_URL

logger = logging.getLogger(__name__)

engine = create_engine(DATABASE_URL, echo=False)


def init_db():
    try:
        SQLModel.metadata.create_all(engine, checkfirst=True)
        logger.info("Database tables initialized successfully")
    except Exception as e:
        # Tables may already exist (e.g. Railway persistent Postgres)
        logger.warning(f"Table creation warning (likely already exists): {e}")


def get_session():
    with Session(engine) as session:
        yield session
