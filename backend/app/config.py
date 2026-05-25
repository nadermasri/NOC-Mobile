import os
from dotenv import load_dotenv

load_dotenv()

# Railway provides DATABASE_URL automatically when you attach a Postgres plugin.
# Some providers use 'postgres://' which psycopg2/SQLModel needs as 'postgresql://'.
_raw_db_url = os.getenv("DATABASE_URL", "postgresql://pocketnoc:pocketnoc@localhost:5432/pocketnoc")
DATABASE_URL = _raw_db_url.replace("postgres://", "postgresql://", 1) if _raw_db_url.startswith("postgres://") else _raw_db_url

DEBUG = os.getenv("DEBUG", "false").lower() == "true"
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", os.getenv("PORT", "8000")))
