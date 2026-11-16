# TESS Phase 11 — Security Review & Hardening Report

**Date:** November 16, 2026  
**Review Status:** COMPLETED & VERIFIED  
**Target Environment:** Local & Hybrid Cloud Production

---

## 1. Threat Model & Overview

The TESS platform acts as an autonomous Personal AI Operating System and Living Companion. Because it interacts with personal memories, documents, web pages, and external productivity systems, it presents distinct threat surfaces:
1. **Server-Side Request Forgery (SSRF):** Exploitation of browser navigation tools to probe loopback services, local network resources, or cloud metadata.
2. **Arbitrary File Access & Path Traversal:** File system tools reading or destroying operating system configuration or credential files.
3. **Action Replay & Unauthorized Execution:** Executing high-risk actions without explicit user confirmation, or replaying confirmation tokens.
4. **Data Leakage & Tenant Isolation:** Cross-user data leakage in shared database instances.
5. **LLM Credential Exposure:** Leaking API tokens or user credentials to model prompts.

---

## 2. Row-Level Security (RLS) & Multi-Tenant Isolation

### Policy Enforcement
All 14 application tables in `backend/schema.sql` have PostgreSQL Row-Level Security enabled:
```sql
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE productivity_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE productivity_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE future_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE proactive_interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_plan_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavioral_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE companion_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE companion_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE companion_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE companion_activity ENABLE ROW LEVEL SECURITY;
```

Each table is governed by tenant-isolation policies matching the authenticated Supabase user ID:
```sql
CREATE POLICY "Users can manage their own data"
  ON <table_name>
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### JWT Authentication in FastAPI
In `backend/app/core/auth.py`:
- Incoming requests extract Bearer JWT tokens from the `Authorization` header.
- Tokens are verified against the Supabase JWT secret or public key.
- The authenticated `user_id` is injected as a dependency into all protected routes.
- Any request without a valid token immediately receives a `401 Unauthorized` response.

---

## 3. Server-Side Request Forgery (SSRF) Hardening

### Vulnerability Identified:
The built-in web tools (`browser_navigate`, `browser_extract`, `browser_fill_form`) previously accepted arbitrary `http` or `https` URLs without blocking internal network endpoints.

### Hardening Implemented:
In `backend/app/services/tools/builtin/browser.py`, strict URL validation was implemented via `is_safe_url`:
```python
BLOCKED_HOSTNAMES = {
    "localhost",
    "127.0.0.1",
    "0.0.0.0",
    "::1",
    "metadata.google.internal",
    "instance-data",
}

def is_safe_url(url_str: str) -> bool:
    try:
        parsed = urlparse(url_str.strip())
        if parsed.scheme not in ("http", "https"):
            return False
        hostname = parsed.hostname
        if not hostname:
            return False
        hostname_lower = hostname.lower()
        if hostname_lower in BLOCKED_HOSTNAMES:
            return False
        if (
            hostname_lower.endswith(".local")
            or hostname_lower.endswith(".internal")
            or hostname_lower.endswith(".localhost")
        ):
            return False

        # Validate IP addresses against private / loopback / link-local / cloud metadata
        try:
            ip = ipaddress.ip_address(hostname_lower)
            if (
                ip.is_private
                or ip.is_loopback
                or ip.is_link_local
                or ip.is_reserved
                or ip.is_multicast
                or ip.is_unspecified
            ):
                return False
        except ValueError:
            pass

        return True
    except Exception:
        return False
```

### Protection Coverage:
- Blocks Loopback addresses (`127.0.0.1`, `localhost`, `::1`).
- Blocks Link-local and cloud metadata addresses (`169.254.169.254`, `metadata.google.internal`).
- Blocks Private RFC-1918 subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).
- Verified via automated unit tests in `tests/test_phase8.py`.

---

## 4. File System & Path Traversal Hardening

### Vulnerability Identified:
Document and file management tools (`file_read`, `file_search`, `file_modify`) could potentially access or delete arbitrary system files if passed paths outside authorized workspaces.

### Hardening Implemented:
In `backend/app/services/tools/builtin/files.py`, canonical path validation was implemented via `is_safe_file_path`:
```python
RESTRICTED_SYSTEM_DIRS = (
    "/etc",
    "/sys",
    "/proc",
    "/dev",
    "/boot",
    "/root",
    "/bin",
    "/sbin",
    "/usr",
    "/var/run",
    "/lib",
    "/lib64",
)

def is_safe_file_path(path: str) -> bool:
    try:
        resolved = os.path.realpath(os.path.abspath(path.strip()))
        if resolved == "/" or any(resolved == r or resolved.startswith(r + "/") for r in RESTRICTED_SYSTEM_DIRS):
            return False
        return True
    except Exception:
        return False
```

### Protection Coverage:
- System roots and critical operating system directories cannot be read, searched, modified, deleted, or moved into.
- Prevents directory traversal attacks (`../../etc/passwd`).
- Validates both source `target_path` and destination path on file moves.
- Verified via automated unit tests in `tests/test_phase8.py`.

---

## 5. High-Risk Action Confirmation & Replay Prevention

### Confirmation Architecture:
1. When an agent creates an execution plan involving HIGH risk tools (`file_modify`, `browser_fill_form`, `gmail_send`, `calendar_create_event`, `openproject_update_task`):
   - The plan is marked `requires_confirmation = True`.
   - The plan state is set to `PENDING_CONFIRMATION`.
   - A cryptographically random confirmation token is generated and hashed (`SHA-256`) before database storage.
2. Unconfirmed Execution Prevention:
   - `ToolRouter.route_and_execute` checks `tool.risk_level == "HIGH"`. If `is_confirmed is False`, execution is immediately halted with `PermissionError`.
3. Single-Use Token Invalidation:
   - Calling `/api/v1/agent/plans/{plan_id}/confirm` transitions the plan to `CONFIRMED`.
   - The confirmation token hash is immediately purged/invalidated, preventing confirmation replay attacks.
   - The plan execution endpoint `/api/v1/agent/plans/{plan_id}/execute` only succeeds if the plan has been confirmed and has not already executed.

---

## 6. LLM Credential Isolation

- Integration credentials (e.g. OpenProject API keys, OAuth tokens) are stored exclusively in the `productivity_connections` table or server environment.
- The LLM Agent Planner and Chat services receive only sanitized summaries and schemas; raw credentials, authorization tokens, and API secret keys are never included in prompts sent to the LLM provider.
- All outbound external requests are handled by backend service classes (`OpenProjectProvider`, etc.) that inject credentials at the HTTP client boundary.

