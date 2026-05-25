#!/bin/bash
set -euo pipefail

# Deploy Pocket NOC backend to Railway
#
# Prerequisites:
#   1. Install Railway CLI: brew install railway
#   2. Login: railway login
#   3. First-time setup (run once):
#      railway init              # creates a new project
#      railway add --plugin postgresql  # adds managed Postgres
#      railway variables set SECRET_KEY=$(openssl rand -hex 32)
#      railway variables set DEBUG=false
#      railway variables set ALLOWED_ORIGINS=https://your-app.up.railway.app
#
# Railway auto-provides: DATABASE_URL, PORT, PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE

cd "$(dirname "$0")/../backend"

echo "=== Pocket NOC — Railway Deploy ==="
echo ""

# Check if railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found. Install it:"
    echo "  brew install railway"
    echo ""
    echo "Then login:"
    echo "  railway login"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "Not logged in. Run: railway login"
    exit 1
fi

echo "Deploying to Railway..."
railway up --detach

echo ""
echo "Deploy started! Railway will:"
echo "  1. Build your Docker image"
echo "  2. Run health check on /api/health"
echo "  3. Route traffic to the new instance"
echo ""
echo "Check status:"
echo "  railway status"
echo "  railway logs"
echo ""
echo "Get your public URL:"
echo "  railway domain"
echo ""
echo "Once you have your Railway URL, build the Flutter app:"
echo "  ./scripts/build_android.sh https://your-app.up.railway.app"
echo "  ./scripts/build_ios.sh https://your-app.up.railway.app"
