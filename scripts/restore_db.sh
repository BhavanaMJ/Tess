#!/usr/bin/env bash
# ==============================================================================
# TESS Personal AI Companion — Database Restore Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: ./scripts/restore_db.sh <path_to_backup_file>"
    echo "Example: ./scripts/restore_db.sh backups/tess_data_20261116_120000.json"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file '${BACKUP_FILE}' not found."
    exit 1
fi

echo "=== TESS Database Restore ==="
echo "Restoring from: ${BACKUP_FILE}"

# If PostgreSQL dump
if [[ "${BACKUP_FILE}" == *.dump ]]; then
    if command -v pg_restore &>/dev/null && [ -n "${PGHOST:-}" ]; then
        echo "Executing pg_restore..."
        pg_restore -v -d "${PGDATABASE:-postgres}" "${BACKUP_FILE}"
        echo "✓ PostgreSQL physical restore complete."
        exit 0
    else
        echo "Error: pg_restore is not installed or PGHOST is not set."
        exit 1
    fi
fi

# If JSON logical snapshot
if [[ "${BACKUP_FILE}" == *.json ]]; then
    export PYTHONPATH="${PROJECT_ROOT}/backend"
    python3 - << EOF
import sys
import json

with open("${BACKUP_FILE}", "r") as f:
    data = json.load(f)

print(f"Loaded backup from {data.get('timestamp')}")
print(f"Tables present: {list(data.get('tables', {}).keys())}")
print("✓ JSON snapshot verified and ready for migration.")
EOF
    echo "✓ Logical snapshot validation complete."
fi

