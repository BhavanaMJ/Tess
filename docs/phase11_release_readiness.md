# TESS Phase 11 — Release Readiness, Backup & Disaster Recovery Guide

**Date:** November 16, 2026  
**Document Status:** FINAL / PRODUCTION READY  
**Scope:** Linux Desktop, Windows Desktop, Android Mobile, Supabase PostgreSQL Backend

---

## 1. Multi-Platform Release Readiness

### Platform Support Matrix:

| Platform | Target Package | Status | Prerequisites / Build Command |
| :--- | :--- | :--- | :--- |
| **Linux Desktop** | `.deb`, `.AppImage` | **READY** | `sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev libayatana-appindicator3-dev`<br>`cd desktop && npm run tauri build` |
| **Windows Desktop** | `.msi`, `.exe` (NSIS) | **READY** | Windows 10/11 x64, Visual Studio C++ Build Tools, WebView2 Runtime<br>`cd desktop && npm run tauri build` |
| **Android Mobile** | `.apk`, `.aab` | **READY** | Expo SDK 52, Android SDK Platform 34<br>`cd mobile && npx eas-cli build --platform android` |
| **Backend API** | Container / Systemd | **READY** | Python 3.10+, FastAPI, Uvicorn, PostgreSQL / Supabase<br>`uvicorn app.main:app --host 0.0.0.0 --port 8000` |

---

## 2. Production Environment Configuration Checklist

Create `.env` in `backend/` and `desktop/` with production credentials:

### Backend Configuration (`backend/.env`):
```ini
# Supabase Database & Auth
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_KEY=<your-service-role-key-for-migrations-only>
SUPABASE_ANON_KEY=<your-anon-public-key>
SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>

# External Productivity (Optional - for live OpenProject sync)
OPENPROJECT_URL=https://openproject.yourdomain.com
OPENPROJECT_API_KEY=<optional-user-api-key>

# AI Engine Models
AI_PROVIDER=openai  # or anthropic, ollama
OPENAI_API_KEY=sk-...
OLLAMA_BASE_URL=http://localhost:11434
```

### Desktop Configuration (`desktop/.env`):
```ini
VITE_SUPABASE_URL=https://<your-project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-public-key>
VITE_BACKEND_URL=http://localhost:8000
```

### Mobile Configuration (`mobile/.env`):
```ini
EXPO_PUBLIC_SUPABASE_URL=https://<your-project-id>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<your-anon-public-key>
EXPO_PUBLIC_BACKEND_URL=http://10.0.2.2:8000  # For Android Emulator or https://api.yourdomain.com for production
```

---

## 3. Database Backup & Disaster Recovery Procedures

Because TESS stores long-term episodic memories, future trajectory evaluations, companion routines, and user preferences, persistent data protection is critical.

### 3.1 Automated Supabase Backups
If using managed Supabase:
- Daily point-in-time recovery (PITR) is automatically enabled for Pro tier.
- Database backups occur daily at 00:00 UTC.

### 3.2 Manual Logical Backup (pg_dump)
To take a snapshot of the entire TESS schema and user data:
```bash
# Export schema + data to compressed SQL dump
pg_dump -h <db.project.supabase.co> -U postgres -d postgres -F c -b -v -f tess_backup_$(date +%Y%m%d_%H%M%S).dump

# Export plain SQL schema only
pg_dump -h <db.project.supabase.co> -U postgres -d postgres --schema-only -f tess_schema_only.sql
```

### 3.3 Database Restoration Procedure
In the event of database corruption or hardware migration:
```bash
# 1. Re-create base schema if restoring to a fresh Supabase instance:
psql -h <db.project.supabase.co> -U postgres -d postgres -f backend/schema.sql

# 2. Restore data from compressed dump:
pg_restore -h <db.project.supabase.co> -U postgres -d postgres -v -a tess_backup_YYYYMMDD_HHMMSS.dump
```

---

## 4. Operational Monitoring & Health Verification

1. **API Health Endpoint:**
   - Check: `GET /health`
   - Response: `{"status": "ok"}`
2. **Database Connectivity:**
   - Execute query `SELECT COUNT(*) FROM conversations;`
3. **Desktop Mascot Verification:**
   - Ensure the mascot process can communicate with `http://localhost:8000/health` within 15 seconds.
   - Transparent frameless window renders in bottom right corner (`1720, 820` default on 1080p).

