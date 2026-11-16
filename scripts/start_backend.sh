#!/usr/bin/env bash
# ==============================================================================
# TESS Personal AI Companion — Backend Startup Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend"
PID_FILE="/tmp/tess_backend.pid"
PORT=8000
HOST="${HOST:-0.0.0.0}"

echo "=== Starting TESS Backend Service ==="

# 1. Check if backend is already running
if [ -f "${PID_FILE}" ]; then
    PID=$(cat "${PID_FILE}")
    if kill -0 "${PID}" 2>/dev/null; then
        echo "Backend is already running (PID: ${PID}). Use ./scripts/stop_backend.sh first."
        exit 0
    else
        echo "Stale PID file found. Cleaning up..."
        rm -f "${PID_FILE}"
    fi
fi

# Check if port 8000 is occupied by another process
if ss -tlpn "sport = :${PORT}" 2>/dev/null | grep -q ":${PORT}"; then
    EXISTING_PID=$(ss -tlpn "sport = :${PORT}" 2>/dev/null | grep -o 'pid=[0-9]*' | head -n1 | cut -d'=' -f2)
    echo "Warning: Port ${PORT} is occupied by PID ${EXISTING_PID}. Terminating conflicting process..."
    kill "${EXISTING_PID}" 2>/dev/null || true
    sleep 2
fi

# 2. Verify dependencies
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is not installed."
    exit 1
fi

# 3. Start backend daemon
cd "${PROJECT_ROOT}"
export PYTHONPATH="backend"
nohup python3 -m uvicorn app.main:app --host "${HOST}" --port "${PORT}" > /tmp/tess_uvicorn.log 2>&1 &
NEW_PID=$!
disown || true
echo "${NEW_PID}" > "${PID_FILE}"

echo "Started backend process with PID: ${NEW_PID}"

# 4. Wait for healthy response
MAX_ATTEMPTS=15
ATTEMPT=1
echo "Waiting for backend health check on http://${HOST}:${PORT}/health..."

while [ ${ATTEMPT} -le ${MAX_ATTEMPTS} ]; do
    if curl -s "http://${HOST}:${PORT}/health" | grep -q '"status":"ok"'; then
        echo "✓ Backend is healthy and ready on http://${HOST}:${PORT}"
        exit 0
    fi
    sleep 1
    ATTEMPT=$((ATTEMPT + 1))
done

echo "Error: Backend failed to respond healthy within ${MAX_ATTEMPTS} seconds. Check /tmp/tess_uvicorn.log"
exit 1

