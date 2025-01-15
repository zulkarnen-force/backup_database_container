#!/bin/bash

# Default values
DB_TYPE=""
DB_NAME=""
CONTAINER_NAME=""
USERNAME=""
PASSWORD=""

# Help function
usage() {
    echo "Usage: $0 --db_type <db_type> --db_name <db_name> --container <container_name> --username <username> --password <password>"
    echo "  -t, --db_type       Database type (psql, mysql, etc.)"
    echo "  -n, --db_name       Database name"
    echo "  -c, --container     Docker container name"
    echo "  -u, --username      Username for the database"
    echo "  -p, --password      Password for the database"
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
