import logging
from sqlalchemy import text
from sqlmodel import SQLModel, create_engine, Session
from app.config import DATABASE_URL

logger = logging.getLogger(__name__)

engine = create_engine(DATABASE_URL, echo=False)


def init_db():
    """Create tables if they don't exist. Safe to call from multiple workers."""
    try:
        # Check if tables already exist before running create_all
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT tablename FROM pg_tables WHERE schemaname = 'public'")
            )
            existing = {row[0] for row in result}

        if existing:
            logger.info(f"Database already has tables: {existing}")
        else:
            SQLModel.metadata.create_all(engine)
            logger.info("Database tables created successfully")
    except Exception as e:
        logger.warning(f"DB init: {e}")


def get_session():
    with Session(engine) as session:
        yield session
