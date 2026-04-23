#!/bin/bash
# ============================================================
# Backup agent configurations
# CRITICAL: Run this regularly to prevent data loss
# ============================================================

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

mkdir -p "$BACKUP_DIR"

echo "Backing up agent configurations..."
docker run --rm \
    -v agent-configs:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/agent-configs_$TIMESTAMP.tar.gz -C / data

echo "Backing up Paperclip data..."
docker run --rm \
    -v paperclip-config:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/paperclip-config_$TIMESTAMP.tar.gz -C / data

echo ""
echo "Backups saved to ./backups/"
ls -la ./backups/