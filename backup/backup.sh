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

# Define backup directories
backup_parent_dir="/backup/STEREOV-SERVER/backup/docker"
backup_dir="$backup_parent_dir/$(date +'%Y-%m-%d')"
backup_volume_dir="$backup_dir/volumes"
backup_container_dir="$backup_dir/containers"

# Create backup directories if they don't exist
mkdir -p "$backup_dir"
mkdir -p "$backup_volume_dir"
mkdir -p "$backup_container_dir"

# Backup running containers
echo "$(date +"%m/%d/%Y %H:%M:%S"): Backing up running containers..."
running_containers=$(docker ps --quiet)
for container_id in $running_containers; do
    container_name=$(docker inspect --format '{{.Name}}' "$container_id" | cut -c2-)
    container_backup_archive="$backup_container_dir/$container_name.tar"


    # Export the container filesystem to a tarball
    docker export "$container_id" > "$container_backup_archive"

    echo "$(date +"%m/%d/%Y %H:%M:%S"): Backup of container '$container_name' completed."
done
echo "$(date +"%m/%d/%Y %H:%M:%S"): All running containers backed up to '$backup_container_dir'."


# Backup volumes
echo "$(date +"%m/%d/%Y %H:%M:%S"): Backing up volumes..."
volumes=$(docker volume ls --quiet)
for volume in $volumes; do
    volume_name=$(docker volume inspect --format '{{.Name}}' "$volume")

    # Backup the volume by copying its contents to the backup directory
    docker run --rm -v "$volume":/volume -v "$backup_volume_dir":/backup ubuntu tar cvf "backup/$volume.tar" volume > /dev/null

    echo "$(date +"%m/%d/%Y %H:%M:%S"): Backup of volume '$volume_name' completed."
done

echo "$(date +"%m/%d/%Y %H:%M:%S"): All volumes backed up to '$backup_volume_dir'."

# Cleanup function
cleanup() {
    # Get the dates to keep for volumes
    keep_dates=$(get_last_three_sundays; get_last_three_months; ls -dt $backup_parent_dir/* | head -n 3)

    # Loop through all backup directories for volumes
    for dir in "$backup_parent_dir"/*; do
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

# rclone sync /backup b2:STEREOV-SERVER-BACKUP
# echo "$(date +"%m/%d/%Y %H:%M:%S"): Sync /backup to b2:STEREOV-SERVER-BACKUP/backup completed."
