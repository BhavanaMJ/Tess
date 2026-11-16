# TESS Phase 12 — Personal Infrastructure Operations Guide

**Date:** November 16, 2026  
**Target Environment:** Private Linux Workstation (Ubuntu/Debian)  
**Status:** FULLY OPERATIONAL

---

## 1. Process Lifecycle & Management

To guarantee reliable daily use without memory leaks, port conflicts, or duplicate backend processes, TESS includes dedicated process control scripts under `scripts/`.

### Startup & Shutdown Scripts:
- **Start Backend:** [scripts/start_backend.sh](file:///home/bhavanamj/Desktop/Tess/scripts/start_backend.sh)
  - Checks if backend is already running via PID file `/tmp/tess_backend.pid` and port query.
  - Automatically terminates conflicting orphaned processes on port 8000.
  - Starts FastAPI daemon under `PYTHONPATH=backend python3 -m uvicorn app.main:app --host 127.0.0.1 --port 8000`.
  - Loops and verifies the `/health` endpoint until healthy response (`{"status":"ok"}`).
- **Stop Backend:** [scripts/stop_backend.sh](file:///home/bhavanamj/Desktop/Tess/scripts/stop_backend.sh)
  - Sends `SIGTERM` for graceful teardown (database connections, open file handles).
  - Waits up to 10 seconds before issuing `SIGKILL` if a hung thread persists.
  - Cleans up PID file.

### CLI Usage:
```bash
# Start backend
./scripts/start_backend.sh

# Check system health
./scripts/healthcheck.sh

# Stop backend
./scripts/stop_backend.sh
```

---

## 2. Health Monitoring & Diagnostics

The diagnostic script [scripts/healthcheck.sh](file:///home/bhavanamj/Desktop/Tess/scripts/healthcheck.sh) validates the entire personal runtime in one execution:
1. **FastAPI HTTP Endpoint:** Tests `GET http://127.0.0.1:8000/health`.
2. **Ollama Service:** Queries `http://127.0.0.1:11434/api/tags` and reports active model count.
3. **Voice Engine:** Verifies that `faster_whisper` and `pyttsx3` can import and run on CPU.
4. **Desktop GUI Environment:** Verifies active `DISPLAY` (`:1`) or `WAYLAND_DISPLAY`.

---

## 3. Log Rotation & Sensitive Data Masking

Configured in [backend/app/core/logging_config.py](file:///home/bhavanamj/Desktop/Tess/backend/app/core/logging_config.py):
- **Log Location:** `logs/tess_backend.log`
- **Rotation Policy:** `RotatingFileHandler` with 10 MB file cap and 5 backup archives (50 MB maximum disk footprint).
- **Sensitive Data Masking:** Custom `SensitiveDataMasker` automatically intercepts and redacts:
  - Authorization Bearer tokens: `Bearer eyJ...` -> `Bearer [MASKED_TOKEN]`.
  - Passwords and secret keys: `api_key='sk-1234...'` -> `api_key='sk-1****'`.
  - Basic Auth API tokens: `apikey:...` -> `apikey:[MASKED]`.

---

## 4. Database Backup & Disaster Recovery

### Automated Logical JSON Snapshot:
Execute [scripts/backup_db.sh](file:///home/bhavanamj/Desktop/Tess/scripts/backup_db.sh):
```bash
./scripts/backup_db.sh
```
- Exports all user tables (`conversations`, `messages`, `memories`, `productivity_tasks`, `future_predictions`, `companion_preferences`, `companion_routines`, `companion_milestones`) to `backups/tess_data_YYYYMMDD_HHMMSS.json`.
- If PostgreSQL credentials (`PGHOST`) and `pg_dump` are present, also exports a compressed `.dump` archive.

### Database Restoration:
```bash
./scripts/restore_db.sh backups/tess_data_YYYYMMDD_HHMMSS.json
```
- Validates JSON format, verifies schema integrity, and prepares data for migration into local or cloud Supabase.

