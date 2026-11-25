# TESS Environment Management & Secrets Governance

This document establishes the architecture, configuration parameters, and database governance protocols across **Development**, **Staging**, and **Production** environments for TESS.

---

## 1. Environment Architecture & Matrix

| Characteristic | Development (Local) | Staging (Pre-Production) | Production |
|---|---|---|---|
| **Purpose** | Feature development, fast feedback | Integration testing, UAT, CI validation | Live end-user operating environment |
| **Branch Association** | `develop`, `feature/*`, `bugfix/*` | `staging`, `release/*` | `main` (tagged releases) |
| **Backend Host** | `http://localhost:8000` / `0.0.0.0:8000` | Staging cluster / Cloud VM | Production cluster |
| **Flutter Host** | `http://localhost:8080` (or Android emulator) | Staging build / TestFlight / Firebase | App Store / Google Play / Web |
| **Desktop Host** | Tauri dev client (`http://localhost:1420`) | Tauri staging binary | Signed production binary |
| **Database** | Local SQLite (`wardrobe.sqlite3`) + Dev Supabase | Dedicated Staging Supabase / DB | Dedicated Production Supabase / DB |
| **AI Provider** | Ollama local (`llama3`) or OpenRouter Dev | Dedicated OpenRouter / Staging Key | High-availability Production Keys |

---

## 2. Configuration & Secrets Governance

### 2.1 Configuration Files
- **Never commit `.env` files**: All `.env`, `.env.local`, `.env.production` files are strictly excluded via `.gitignore`.
- **Reference Templates**: Use `.env.example` in each component directory (`/`, `backend/`, `desktop/`, `mobile/`) to specify required keys without real values.

### 2.2 Core Environment Variables

```env
# Database & Authentication
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ... # (Backend only, never expose to clients)

# Backend URL
BACKEND_URL=http://localhost:8000

# Local Wardrobe Storage
LOCAL_DB_PATH=app/data/wardrobe.sqlite3

# AI Intelligence Providers
AI_PROVIDER=ollama # Options: 'ollama', 'openrouter'
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_MODEL=meta-llama/llama-3-8b-instruct
```

---

## 3. Database & Migration Management

### 3.1 Migration Rules
1. **Sequential Numbering**: Migrations in `backend/migrations/` must follow strict sequential order:
   - `001_wardrobe.sql`
   - `002_wardrobe_capture.sql`
   - `003_laundry_manager.sql`
   - `004_outfit_studio.sql`
   - `005_outfit_calendar.sql`
   - `006_wardrobe_insights.sql`
   - `007_wardrobe_wishlist.sql`
   - `008_garment_metadata_import.sql`
2. **Backward Compatibility**: Migrations must never drop tables or columns currently in use by production code without a multi-phase deprecation cycle.
3. **Staging First**: Every migration must be applied and validated on Staging before touching Production.

### 3.2 Production Data Protection Protocols
Before executing any migration in staging or production:
1. **Trigger Automated Backup**:
   ```bash
   ./scripts/backup_db.sh
   ```
   Backups are written with ISO-8601 timestamps to `backups/db_<timestamp>.sql`.
2. **Verify Backup Validity**:
   Ensure the backup file is non-empty and contains expected table schemas.
3. **Rollback Strategy**:
   If an error occurs during execution, immediately restore using:
   ```bash
   ./scripts/restore_db.sh backups/db_<timestamp>.sql
   ```

### 3.3 SQLite Local Persistence Governance
- The local SQLite engine (`backend/app/core/local_db.py`) runs in **Write-Ahead Logging (WAL)** mode for concurrent reader/writer isolation.
- Automatic schema verification runs on startup to guarantee all necessary tables and indexes exist.
- SQLite files are stored under `backend/app/data/` and must never be committed to Git.
