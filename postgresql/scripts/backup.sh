#!/bin/bash

# PostgreSQL Backup Script
# This script creates a backup of PostgreSQL databases and manages retention

# Configuration
BACKUP_DIR="/var/lib/postgresql/backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.log"

# Ensure backup directory exists
mkdir -p ${BACKUP_DIR}

# Log function
log() {
  echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a ${LOG_FILE}
}

# Start backup process
log "Starting PostgreSQL backup process"

# Get list of databases excluding templates and postgres
DATABASES=$(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres')" | tr -d ' ')

# Backup each database
for DB in ${DATABASES}; do
  BACKUP_FILE="${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql.gz"
  log "Backing up database: ${DB} to ${BACKUP_FILE}"
  
  # Perform the backup with compression
  pg_dump -U postgres -d ${DB} -F c | gzip > ${BACKUP_FILE}
  
  if [ $? -eq 0 ]; then
    log "Backup of ${DB} completed successfully"
  else
    log "ERROR: Backup of ${DB} failed"
  fi
done

# Create a full backup of all databases
FULL_BACKUP_FILE="${BACKUP_DIR}/full_backup_${TIMESTAMP}.sql.gz"
log "Creating full backup to ${FULL_BACKUP_FILE}"
pg_dumpall -U postgres | gzip > ${FULL_BACKUP_FILE}

if [ $? -eq 0 ]; then
  log "Full backup completed successfully"
else
  log "ERROR: Full backup failed"
fi

# Clean up old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days"
find ${BACKUP_DIR} -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "*.log" -type f -mtime +${RETENTION_DAYS} -delete

# Count remaining backups
BACKUP_COUNT=$(find ${BACKUP_DIR} -name "*.sql.gz" | wc -l)
log "Backup process completed. ${BACKUP_COUNT} backups currently stored."

# Exit with success
exit 0
