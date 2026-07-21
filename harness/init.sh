#!/usr/bin/env bash
# Harness init — idempotent. Leaves the environment running and verified.
# Agents run it at the start of EVERY session (Anthropic pattern).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[1/4] Dependencies…"
# e.g.: pnpm install --frozen-lockfile

echo "[2/4] Configuration…"
[ -f .env ] || { [ -f .env.example ] && cp .env.example .env && echo "  .env creado desde ejemplo"; }

echo "[3/4] Base de datos / migraciones…"
# e.g.: docker compose up -d db && pnpm db:migrate

echo "[4/4] Servidor de desarrollo + smoke test…"
# e.g.: (pnpm dev &) && sleep 3 && curl -sf http://localhost:3000/health

echo "OK — environment ready. Siguiente paso: leer harness/claude-progress.md y feature_list.json"
