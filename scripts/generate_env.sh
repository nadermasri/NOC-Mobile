#!/bin/bash
set -euo pipefail

# Generate a production .env file with random secrets

SECRET_KEY=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -hex 16)

cat > "$(dirname "$0")/../backend/.env" << EOF
# Generated $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# DO NOT COMMIT THIS FILE

DATABASE_URL=postgresql://pocketnoc:${DB_PASSWORD}@db:5432/pocketnoc
DB_PASSWORD=${DB_PASSWORD}
SECRET_KEY=${SECRET_KEY}
DEBUG=false
API_HOST=0.0.0.0
API_PORT=8000
ALLOWED_ORIGINS=https://api.pocketnoc.app
EOF

echo "Production .env generated at backend/.env"
echo "SECRET_KEY and DB_PASSWORD have been randomly generated."
echo ""
echo "IMPORTANT: Back up these values securely. If lost, users will be logged out"
echo "and the database password will need to be reset."
