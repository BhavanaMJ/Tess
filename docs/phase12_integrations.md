# TESS Phase 12 — External Integrations Guide

**Date:** November 16, 2026  
**Status:** CORE SERVICES ACTIVE / OPTIONAL EXTERNAL SERVICES DOCUMENTED

---

## 1. Overview of Personal Integrations

To keep the personal deployment lean, reliable, and private:
- **Active Core Integrations:** Local faster-whisper (STT), local pyttsx3 (TTS), local Ollama LLMs (`llama3.1:8b`, `llama3.2:1b`), Supabase PostgreSQL.
- **Configurable Personal Integrations:** OpenProject (Task & Worklog tracking), Ollama Vision / OpenRouter Vision (Screen Intelligence).
- **Optional Personal Integrations:** Google Mail & Calendar.

---

## 2. OpenProject Integration Setup

### Overview:
TESS integrates directly with OpenProject API v3 (`/api/v3/work_packages` and `/api/v3/time_entries`) to track personal projects, deadlines, and automatically log time spent via autonomous agent actions.

### Step-by-Step Activation:
1. **Deploy OpenProject (Local Docker):**
   ```bash
   docker run -d -p 8080:80 \
     --name openproject \
     -e OPENPROJECT_SECRET_KEY_BASE=secret \
     -e OPENPROJECT_HOST__NAME=localhost:8080 \
     -e OPENPROJECT_HTTPS=false \
     openproject/community:14
   ```
2. **Obtain API Token:**
   - Log into OpenProject at `http://localhost:8080`.
   - Navigate to: **My Account** -> **Access Tokens** -> **API** -> Click **Generate**.
3. **Register Credentials in TESS:**
   Via API or Supabase Studio:
   ```sql
   INSERT INTO productivity_connections (
       user_id,
       provider,
       base_url,
       credential_reference,
       connected_at,
       status
   ) VALUES (
       '<your-user-uuid>',
       'openproject',
       'http://localhost:8080',
       '<your-api-token>',
       NOW(),
       'active'
   );
   ```
4. **Agent Worklog Verification:**
   - The agent tool `openproject_update_worklog` accepts `task_id`, `hours`, and `comment`.
   - Upon confirmed execution, it posts to `/api/v3/time_entries` and records the time against the project.

---

## 3. Screen Intelligence (Multimodal Context) Setup

### User Consent & Safeguard:
Screen analysis is strictly explicit. TESS only captures or analyzes the screen when the user clicks **Analyze Screen** or triggers a screen-related voice command.

### Vision Provider Configuration:

#### Option A: Local Ollama Multimodal Vision (Zero Cloud Dependence)
1. Pull the `llava` vision model in your running Ollama instance:
   ```bash
   ollama pull llava
   ```
2. Set in `backend/.env`:
   ```ini
   AI_PROVIDER=ollama
   OLLAMA_MODEL=llava
   OLLAMA_BASE_URL=http://localhost:11434
   ```

#### Option B: OpenRouter Multimodal Vision (Cloud API)
1. Obtain an API key from [OpenRouter](https://openrouter.ai).
2. Set in `backend/.env`:
   ```ini
   AI_PROVIDER=openrouter
   OPENROUTER_API_KEY=sk-or-v1-...
   OPENROUTER_MODEL=google/gemini-flash-1.5
   ```

---

## 4. Google Mail & Calendar (Optional Setup)

If you wish to link your personal Google account:
1. Go to [Google Cloud Console](https://console.cloud.google.com) and create a project.
2. Enable **Gmail API** and **Google Calendar API**.
3. Configure OAuth Consent Screen and add scopes:
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/calendar`
4. Create Web OAuth Client ID.
5. Add credentials to `backend/.env`:
   ```ini
   GOOGLE_CLIENT_ID=<client-id>.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=<client-secret>
   ```
*Note: If unconfigured, TESS operates normally using internal task and scheduling features without blocking the platform.*

