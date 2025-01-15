# Docker Database Backup Script

A Bash script to back up databases running in Docker containers. This script supports multiple database types such as PostgreSQL and MySQL. Backups are stored on the host machine with a timestamped filename, and the script automatically retains only the latest 3 backups per container.

## Features

- Supports PostgreSQL (`psql`) and MySQL (`mysql`) databases.
- Dynamically accepts database type, container name, database name, username, and password as arguments.
- Stores backups in the `~/docker-backup/<container_name>/` directory with filenames in the format `<timestamp>.sql`.
- Automatically deletes older backups, retaining only the most recent 3 backups.

## Requirements

- Docker installed on the host machine.
- A running Docker container with the database to be backed up.
- Bash shell (Linux/macOS).

## Usage

### Command

```bash
bash backup-database.sh -t <db_type> -n <db_name> -c <container_name> -u <username> -p <password>
```

```
./backup.bash -c db.sotabar -u root -p password -t mysql -n sotabar
```

### Running the Script Without Downloading

```
curl -sSL https://raw.githubusercontent.com/zulkarnen-force/backup_database_container/refs/heads/main/backup.bash | bash -s -- -c db.sotabar -u root -p password -t mysql -n sotabar
```

## Crontab

```bash
mkdir -p ~/docker-backup/logs/
```

### Every

Backup MySQL database every day at 2 AM

```
0 2 * * * curl -sSL https://raw.githubusercontent.com/zulkarnen-force/backup_database_container/refs/heads/main/backup.bash | bash -s -- -c db.sotabar -u root -p password -t mysql -n sotabar >> ~/docker-backup/logs/backup.log 2>&1
```

```bash
# Every dat at 2 AM
0 2 * * * 

# Every hour
0 * * * * 
```
