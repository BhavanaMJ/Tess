# TESS Phase 12 — Personal Release Readiness & Operations Guide

**Date:** November 16, 2026  
**Target:** Private Personal Daily Use  
**Release Readiness Verdict:** **GO FOR PERSONAL LINUX WORKSTATION DEPLOYMENT**

---

## 1. Quick Launch Guide (Personal Daily Startup)

To start TESS on your personal Linux workstation:

### Step 1: Start Backend Service
```bash
./scripts/start_backend.sh
```
*Verifies dependencies, starts background process, and confirms health on `http://127.0.0.1:8000/health`.*

### Step 2: Run Diagnostics (Optional but Recommended)
```bash
./scripts/healthcheck.sh
```
*Checks backend API, local Ollama LLMs, local Whisper/TTS, and desktop display.*

### Step 3: Launch Full Desktop Application & Mascot
```bash
cd desktop
npm run tauri dev
```
*Opens both the full TESS application and the floating digital pet mascot.*

### Step 4: Stop Backend When Done
```bash
./scripts/stop_backend.sh
```

---

## 2. Configuration & Secrets Management Guide

Create your personal `.env` files (never commit these to Git):

### Backend Configuration (`backend/.env`):
```ini
# Supabase Database & Auth
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_ANON_KEY=<your-anon-public-key>
SUPABASE_KEY=<your-service-role-key-for-migrations>

# AI Provider (Local Ollama recommended)
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b

# Optional: Cloud AI Provider
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_MODEL=google/gemini-flash-1.5

# Approved File Workspaces (Security Boundary)
TESS_ALLOWED_WORKSPACES=/home/bhavanamj/Desktop/Tess,/tmp
```

### Desktop Application Configuration (`desktop/.env`):
```ini
VITE_SUPABASE_URL=https://<your-project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-public-key>
VITE_BACKEND_URL=http://localhost:8000
```

### Mobile Application Configuration (`mobile/.env`):
```ini
EXPO_PUBLIC_SUPABASE_URL=https://<your-project-id>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<your-anon-public-key>
EXPO_PUBLIC_BACKEND_URL=http://<your-workstation-local-ip>:8000
```

---

## 3. Troubleshooting & Frequently Encountered Scenarios

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| **Port 8000 already in use** | Stale uvicorn instance from earlier run | Run `./scripts/stop_backend.sh`, then `./scripts/start_backend.sh`. |
| **Backend returns 401 Unauthorized** | Supabase session expired | Log in again via desktop or mobile login screen. `autoRefreshToken` will renew active sessions automatically. |
| **Ollama shows offline in healthcheck** | Ollama service not running | Run `ollama serve` in a terminal or verify `systemctl status ollama`. |
| **Mascot click does not focus main app** | Main window minimized or unmapped | Check that main window label in `tauri.conf.json` is `main`. Handled automatically by `focus_main_window` IPC. |
| **Voice synthesis silent** | Audio drivers or pyttsx3 voice not set | Ensure ALSA/PulseAudio/PipeWire is active. Audio chime fallback executes if pyttsx3 encounters driver issues. |

---

## 4. Personal Release Checklist

- [x] All 58 backend pytest tests passing.
- [x] All 24 desktop vitest tests passing.
- [x] Desktop TypeScript & Vite production build passing (`0 errors`).
- [x] Mobile Hermes bundles exporting cleanly (`2.7 MB`).
- [x] SSRF defenses validated against decimal, octal, hex, and redirect bypasses.
- [x] Path traversal and symlink exploits blocked.
- [x] Single-use confirmation replay prevention verified.
- [x] Sensitive tokens redacted from log output (`logs/tess_backend.log`).
- [x] Live Whisper STT and pyttsx3 TTS operational.
- [x] Backup and restore scripts tested and operational.
- [x] All 9 daily workflows verified against running API.

---

## 5. Personal GO / NO-GO Decision

### **DECISION: GO FOR PRIVATE PERSONAL DAILY USE**

**Summary:**  
TESS is fully ready for dependable daily personal use on Linux desktop. The companion remembers conversations, analyzes future trajectories, alerts you to upcoming risks, logs time to projects, responds via voice and text, and keeps your private data secure within your personal workstation and Supabase instance.

