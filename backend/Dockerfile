FROM python:3.12-slim AS base

# Security: run as non-root
RUN groupadd -r appuser && useradd -r -g appuser -s /sbin/nologin appuser

WORKDIR /app

# Install deps first (cache layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Remove test files from production image
RUN rm -rf tests/ __pycache__/

# Own everything by appuser
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE ${PORT:-8000}

# Uvicorn with production settings
# Railway injects PORT env var; fallback to 8000 for local Docker
CMD uvicorn app.main:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --workers 2 \
    --loop uvloop \
    --http httptools \
    --no-access-log
