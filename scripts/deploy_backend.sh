#!/bin/bash
set -euo pipefail

# Deploy backend to Fly.io
# Prerequisites:
#   1. Install flyctl: curl -L https://fly.io/install.sh | sh
#   2. Login: fly auth login
#   3. First time: fly launch (from backend/ dir)
#   4. Set secrets: fly secrets set SECRET_KEY=... DB_PASSWORD=...
#   5. Create Postgres: fly postgres create --name pocket-noc-db
#   6. Attach: fly postgres attach pocket-noc-db

cd "$(dirname "$0")/../backend"

echo "Deploying backend to Fly.io..."
fly deploy

echo ""
echo "Checking health..."
sleep 5
fly status
echo ""
echo "Health check:"
curl -s "https://pocket-noc-api.fly.dev/api/health" | python3 -m json.tool
