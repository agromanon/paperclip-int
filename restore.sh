#!/bin/bash
# ============================================================
# Restore from backup
# Usage: ./restore.sh backups/agent-configs_20240423_120000.tar.gz
# ============================================================

set -e

BACKUP_FILE=$1

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: ./restore.sh <backup-file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -la backups/
    exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Creating volume backup of current state..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker run --rm \
    -v agent-configs:/data \
    -v $(pwd)/backups:/backup \
    alpine tar czf /backup/pre-restore_$TIMESTAMP.tar.gz -C / data 2>/dev/null || true

echo "Restoring from: $BACKUP_FILE"

# Create temp volume
docker volume create agent-configs-temp

# Extract to temp volume
docker run --rm \
    -v agent-configs-temp:/data \
    -v $(pwd):/backup \
    alpine tar xzf /backup/$BACKUP_FILE -C /

# Stop current runtime
docker compose -f docker-compose.runtime.yml down

# Remove old volume and rename temp
docker volume rm agent-configs
docker volume create agent-configs

# Copy data
docker run --rm \
    -v agent-configs-temp:/from \
    -v agent-configs:/to \
    alpine sh -c "cp -r /from/* /to/"

docker volume rm agent-configs-temp

echo "Restore complete. Starting runtime..."
docker compose -f docker-compose.runtime.yml up -d