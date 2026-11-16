#!/usr/bin/env bash
# ==============================================================================
# TESS Personal AI Companion — Health Check & Diagnostics Script
# ==============================================================================
set -euo pipefail

BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8000}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

echo "=== TESS System Health Diagnostics ==="

# 1. Backend API Check
echo -n "Checking Backend API (${BACKEND_URL}/health)... "
BACKEND_STATUS=$(curl -s -m 5 "${BACKEND_URL}/health" 2>/dev/null || echo '{"status":"down"}')
if echo "${BACKEND_STATUS}" | grep -q '"status":"ok"'; then
    echo "✓ ONLINE"
else
    echo "✗ OFFLINE (${BACKEND_STATUS})"
fi

# 2. Ollama Local LLM Check
echo -n "Checking Ollama Service (${OLLAMA_URL}/api/tags)... "
OLLAMA_RESP=$(curl -s -m 5 "${OLLAMA_URL}/api/tags" 2>/dev/null || echo "")
if [ -n "${OLLAMA_RESP}" ] && echo "${OLLAMA_RESP}" | grep -q 'models'; then
    MODEL_COUNT=$(echo "${OLLAMA_RESP}" | grep -o '"name":' | wc -l)
    echo "✓ ONLINE (${MODEL_COUNT} models available)"
else
    echo "✗ OFFLINE or UNREACHABLE"
fi

# 3. Voice STT & TTS Availability
echo -n "Checking Local Voice Engines (faster-whisper, pyttsx3)... "
if python3 -c "import faster_whisper, pyttsx3; print('OK')" 2>/dev/null | grep -q "OK"; then
    echo "✓ AVAILABLE (CPU Whisper & pyttsx3)"
else
    echo "✗ MISSING DEPENDENCIES"
fi

# 4. Display & Mascot Window Environment
echo -n "Checking GUI Desktop Display Environment... "
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "✓ DISPLAY DETECTED (DISPLAY=${DISPLAY:-none}, WAYLAND=${WAYLAND_DISPLAY:-none})"
else
    echo "! HEADLESS ENVIRONMENT (No X11 or Wayland display)"
fi

echo "======================================"

