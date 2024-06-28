#!/bin/bash

# Change this location based on your setup
system_backup_dir="/mnt/vps-server-backup"
docker_vol_backup_parent_dir="/mnt/docker-vol-backup"

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

# Define backup directories
backup_dir="$docker_vol_backup_parent_dir/$(date +'%Y-%m-%d')"

# Backup volumes
echo "$(date +"%m/%d/%Y %H:%M:%S"): Backing up volumes..."
volumes=$(docker volume ls --quiet)
for volume in $volumes; do
    volume_name=$(docker volume inspect --format '{{.Name}}' "$volume")

    # Backup the volume by copying its contents to the backup directory
    docker run --rm -v "$volume":/volume -v "$backup_dir":/backup ubuntu tar cvf "backup/$volume.tar" volume > /dev/null

    echo "$(date +"%m/%d/%Y %H:%M:%S"): Backup of volume '$volume_name' completed."
done

echo "$(date +"%m/%d/%Y %H:%M:%S"): All volumes backed up to '$backup_dir'."

# Cleanup function
cleanup() {
    # Get the dates to keep for volumes
    keep_dates=$(get_last_three_sundays; get_last_three_months; ls -dt $docker_vol_backup_parent_dir/* | head -n 3)

    # Loop through all backup directories for volumes
    for dir in "$docker_vol_backup_parent_dir"/*; do
        # Get the date from the directory name
        dir_date=$(basename "$dir")

        # If the date is not in the list of dates to keep, delete the directory
        if ! grep -q "$dir_date" <<< "$keep_dates"; then
            rm -rf "$dir"
            echo "$(date +"%m/%d/%Y %H:%M:%S"): Deleted old volume backup '$dir'."
        fi
    done
}

# Run the cleanup function
cleanup
