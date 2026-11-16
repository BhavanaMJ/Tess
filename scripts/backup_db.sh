#!/usr/bin/env bash
# ==============================================================================
# TESS Personal AI Companion — Database Backup Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/tess_backup_${TIMESTAMP}.dump"
JSON_BACKUP="${BACKUP_DIR}/tess_data_${TIMESTAMP}.json"

mkdir -p "${BACKUP_DIR}"

echo "=== TESS Database Backup ==="

# 1. If pg_dump is available and DB credentials provided, run pg_dump
if command -v pg_dump &>/dev/null && [ -n "${PGHOST:-}" ]; then
    echo "Creating PostgreSQL physical dump via pg_dump..."
    pg_dump -Fc -b -v -f "${BACKUP_FILE}"
    echo "✓ PostgreSQL dump saved to ${BACKUP_FILE}"
fi

# 2. Run Python logical snapshot (works via Supabase / postgrest client)
echo "Creating logical JSON snapshot of all TESS tables..."
export PYTHONPATH="${PROJECT_ROOT}/backend"
python3 - << EOF
import os
import json
from datetime import datetime

tables = [
    "conversations",
    "messages",
    "memories",
    "productivity_tasks",
    "future_predictions",
    "proactive_interventions",
    "companion_preferences",
    "companion_routines",
    "companion_milestones",
    "companion_activity"
]

backup_data = {
    "version": "1.0",
    "timestamp": datetime.utcnow().isoformat(),
    "tables": {}
}

# Try connecting via Supabase if configured
try:
    from app.core.config import settings
    from supabase import create_client
    if settings.supabase_url and settings.supabase_anon_key:
        client = create_client(settings.supabase_url, settings.supabase_anon_key)
        for t in tables:
            try:
                res = client.table(t).select("*").execute()
                backup_data["tables"][t] = res.data or []
            except Exception as e:
                backup_data["tables"][t] = []
    else:
        # Schema snapshot
        with open("${PROJECT_ROOT}/backend/schema.sql", "r") as f:
            backup_data["schema_sql"] = f.read()
except Exception as e:
    with open("${PROJECT_ROOT}/backend/schema.sql", "r") as f:
        backup_data["schema_sql"] = f.read()

with open("${JSON_BACKUP}", "w") as out:
    json.dump(backup_data, out, indent=2)

print(f"✓ Logical snapshot saved to ${JSON_BACKUP}")
EOF

echo "✓ Backup completed successfully."

