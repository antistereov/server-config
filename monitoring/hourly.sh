# Check btrfs status
sudo btrfs device stats /
sudo btrfs device stats /data

# Check docker container status
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# Disk usage
df -h | awk '$NF=="/data"{printf "%.2f%\n", $5}'
df -h | awk '$NF=="/data"{printf "%.2f%\n", $5}'
