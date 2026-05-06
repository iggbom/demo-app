#!/usr/bin/env bash
# setup.sh — run once after cloning, before `docker compose up`
set -euo pipefail

# ── Curity license ──────────────────────────────────────────────────────────
if [ ! -f "curity/license.json" ]; then
  echo "⚠️  No Curity license found at curity/license.json"
  echo "   Get a free developer license at https://developer.curity.io"
  echo "   Then place it at curity/license.json and re-run this script."
  exit 1
fi

# ── Frontend env ────────────────────────────────────────────────────────────
if [ ! -f "frontend/.env" ]; then
  cp frontend/.env.example frontend/.env
  echo "Created frontend/.env from .env.example"
fi

echo ""
echo "✅  Setup complete. Run: docker compose up --build"
echo ""
echo "   Curity admin UI → https://localhost:6749/admin  (admin / <your PASSWORD>)"
echo "   API             → http://localhost:8080/api/items"
echo "   Frontend        → http://localhost:3000"
echo ""
echo "   First login: register a user at https://localhost:8443/authn/registration"
echo "   (accept the self-signed cert warning in your browser first)"
