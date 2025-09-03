#!/bin/bash

# Exit on error
set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default values
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create database backup
echo "Creating database backup to $BACKUP_FILE..."
docker-compose exec -T db pg_dump -U $POSTGRES_USER $POSTGRES_DB > "$BACKUP_FILE"

# Compress the backup
gzip -f "$BACKUP_FILE"

echo "Backup completed: ${BACKUP_FILE}.gz"
