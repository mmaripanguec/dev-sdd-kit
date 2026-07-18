#!/usr/bin/env bash
# Harness init — idempotente. Deja el entorno corriendo y verificado.
# Los agentes lo ejecutan al inicio de CADA sesión (patrón Anthropic).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[1/4] Dependencias…"
# ej.: pnpm install --frozen-lockfile

echo "[2/4] Configuración…"
[ -f .env ] || { [ -f .env.example ] && cp .env.example .env && echo "  .env creado desde ejemplo"; }

echo "[3/4] Base de datos / migraciones…"
# ej.: docker compose up -d db && pnpm db:migrate

echo "[4/4] Servidor de desarrollo + smoke test…"
# ej.: (pnpm dev &) && sleep 3 && curl -sf http://localhost:3000/health

echo "OK — entorno listo. Siguiente paso: leer harness/claude-progress.md y feature_list.json"
