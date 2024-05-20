#!/bin/bash

# Navigate to the directory where the script is located
cd "$(dirname "$0")"

# Load .env variables
set -o allexport
source .env
set +o allexport

WG_CONFIG_PATH="./wg0.conf"

# Check if VPN_ENDPOINT_DOMAIN is set
if [ -z "$VPN_ENDPOINT_DOMAIN" ]; then
  echo "VPN_ENDPOINT_DOMAIN is not set in the .env file."
  exit 1
fi

# Get the current IP address for the domain
NEW_IP=$(dig +short "$VPN_ENDPOINT_DOMAIN" | tail -n1)

if [ -z "$NEW_IP" ]; then
  echo "Failed to resolve IP for domain: $VPN_ENDPOINT_DOMAIN"
  exit 1
fi

# Extract current IP from wg0.conf
CURRENT_IP=$(grep -Eo "Endpoint = [^:]*" "$WG_CONFIG_PATH" | awk '{print $3}')

# Update wg0.conf only if the IP has changed
if [ "$CURRENT_IP" != "$NEW_IP" ]; then
  echo "Updating wg0.conf Endpoint from $CURRENT_IP to $NEW_IP"
  sed -i -e "s/Endpoint = $CURRENT_IP:57168/Endpoint = $NEW_IP:57168/" "$WG_CONFIG_PATH"

  # Restart Docker Compose services
  docker compose down && docker compose up -d
else
  echo "wg0.conf Endpoint is already up to date."
fi

echo "Script completed."

