#!/bin/bash

# Default values
DB_TYPE=""
DB_NAME=""
CONTAINER_NAME=""
USERNAME=""
PASSWORD=""
REMOTE_NAME=""

# Help function
usage() {
    echo "Usage: $0 --db_type <db_type> --db_name <db_name> --container <container_name> --username <username> --password <password> [--remote-name <remote_name>]"
    echo "  -t, --db_type       Database type (psql, mysql, etc.)"
    echo "  -n, --db_name       Database name"
    echo "  -c, --container     Docker container name"
    echo "  -u, --username      Username for the database"
    echo "  -p, --password      Password for the database"
    echo "  -r, --remote-name   rclone remote name for syncing backups"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--db_type) DB_TYPE="$2"; shift ;;
        -n|--db_name) DB_NAME="$2"; shift ;;
        -c|--container) CONTAINER_NAME="$2"; shift ;;
        -u|--username) USERNAME="$2"; shift ;;
        -p|--password) PASSWORD="$2"; shift ;;
        -r|--remote-name) REMOTE_NAME="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Validate required arguments
if [[ -z "$DB_TYPE" || -z "$DB_NAME" || -z "$CONTAINER_NAME" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "Error: Missing required arguments"
    usage
fi

# Generate timestamp for the filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/docker-backup/${CONTAINER_NAME}
BACKUP_FILE=${BACKUP_DIR}/${TIMESTAMP}.sql

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Database backup command
case $DB_TYPE in
    psql)
        # Backup for PostgreSQL
        docker exec "$CONTAINER_NAME" pg_dump -U "$USERNAME" "$DB_NAME" > "$BACKUP_FILE"
        ;;
    mysql)
        # Backup for MySQL
        docker exec "$CONTAINER_NAME" mysqldump -u"$USERNAME" -p"$PASSWORD" "$DB_NAME" > "$BACKUP_FILE"
        ;;
    *)
        echo "Unsupported database type: $DB_TYPE"
        exit 1
        ;;
esac

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup successful: $BACKUP_FILE"
else
    echo "Backup failed"
    exit 1
fi

# Retain only the latest 3 backups
BACKUP_FILES=($(ls -1t "$BACKUP_DIR"/*.sql))  # List files sorted by modification time (newest first)
TOTAL_FILES=${#BACKUP_FILES[@]}

if [ "$TOTAL_FILES" -gt 3 ]; then
    for ((i=3; i<TOTAL_FILES; i++)); do
        rm -f "${BACKUP_FILES[$i]}"  # Delete old files
    done
    echo "Old backups deleted, retaining only the latest 3 backups."
else
    echo "No old backups to delete, total backups: $TOTAL_FILES."
fi

# Sync to remote storage if remote name is provided
if [[ -n "$REMOTE_NAME" ]]; then
    echo "Syncing backups to remote: $REMOTE_NAME"
    rclone sync "$BACKUP_DIR" "$REMOTE_NAME:/docker-backup/${CONTAINER_NAME}" --progress
    if [ $? -eq 0 ]; then
        echo "Backup synced successfully to remote: $REMOTE_NAME"
    else
        echo "Failed to sync backup to remote: $REMOTE_NAME"
        exit 1
    fi
fi
