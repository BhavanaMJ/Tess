#!/usr/bin/env bash
# ==============================================================================
# TESS Personal AI Companion — Backend Shutdown Script
# ==============================================================================
set -euo pipefail

PID_FILE="/tmp/tess_backend.pid"
PORT=8000

echo "=== Stopping TESS Backend Service ==="

TARGET_PID=""

if [ -f "${PID_FILE}" ]; then
    TARGET_PID=$(cat "${PID_FILE}")
elif ss -tlpn "sport = :${PORT}" 2>/dev/null | grep -q ":${PORT}"; then
    TARGET_PID=$(ss -tlpn "sport = :${PORT}" 2>/dev/null | grep -o 'pid=[0-9]*' | head -n1 | cut -d'=' -f2)
fi

if [ -z "${TARGET_PID}" ]; then
    echo "No running backend found on port ${PORT} or in ${PID_FILE}."
    rm -f "${PID_FILE}"
    exit 0
fi

echo "Sending SIGTERM to PID ${TARGET_PID}..."
kill "${TARGET_PID}" 2>/dev/null || true

# Wait up to 10 seconds for graceful shutdown
TIMEOUT=10
while [ ${TIMEOUT} -gt 0 ]; do
    if ! kill -0 "${TARGET_PID}" 2>/dev/null; then
        echo "✓ Backend process ${TARGET_PID} stopped gracefully."
        rm -f "${PID_FILE}"
        exit 0
    fi
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
done

echo "Process ${TARGET_PID} did not terminate within timeout. Sending SIGKILL..."
kill -9 "${TARGET_PID}" 2>/dev/null || true
rm -f "${PID_FILE}"
echo "✓ Backend process force-terminated."

