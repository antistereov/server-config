#!/bin/bash

echo ""
echo "$(date +"%m/%d/%Y %H:%M:%S"): Starting backup script."

# Function to get the date of the last three Sundays
get_last_three_sundays() {
    for i in {1..3}; do
        date --date="last Sunday -$i week" +%Y-%m-%d
    done
}

# Function to get the date of the first day of the last three months
get_last_three_months() {
    for i in {1..3}; do
        date --date="-$i month" +%Y-%m-01
    done
}

# Define backup directory
backup_dir="/backup/volumes/$(date +'%Y-%m-%d')"

# Create backup directory if it doesn't exist
mkdir -p "$backup_dir"

# Get list of Docker volumes
volumes=$(docker volume ls --quiet)

# Loop through each volume and back it up
for volume in $volumes; do
    volume_name=$(docker volume inspect --format '{{.Name}}' "$volume")
    volume_backup_dir="$backup_dir/$volume_name"

    # Create backup directory for the volume
    mkdir -p "$volume_backup_dir"

    # Backup the volume by copying its contents to the backup directory
    docker run --rm -v "$volume":/"$volume_name" -v "$volume_backup_dir":/backup alpine tar -cC / "$volume_name" > /dev/null

    echo "$(date +"%m/%d/%Y %H:%M:%S"): Backup of volume '$volume_name' completed."
done

echo "$(date +"%m/%d/%Y %H:%M:%S"): All volumes backed up to '$backup_dir'."

# Cleanup function
cleanup() {
    # Get the dates to keep
    keep_dates=$(get_last_three_sundays; get_last_three_months; ls -dt /backup/volumes/* | head -n 3)

    # Loop through all backup directories
    for dir in /backup/volumes/*; do
        # Get the date from the directory name
        dir_date=$(basename "$dir")

        # If the date is not in the list of dates to keep, delete the directory
        if ! grep -q "$dir_date" <<< "$keep_dates"; then
            rm -rf "$dir"
            echo "$(date +"%m/%d/%Y %H:%M:%S"): Deleted old backup '$dir'."
        fi
    done
}

# Run the cleanup function
cleanup

rclone sync /backup b2:STEREOV-SERVER-BACKUP/backup
echo "$(date +"%m/%d/%Y %H:%M:%S"): Sync /backup to b2:STEREOV-SERVER-BACKUP/backup completed."
