#!/bin/bash

ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
    read -p ".env file already exists. Overwrite? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Enter the secrets for Homepage services:"
echo ""

read -p "UniFi username [homepage]: " UNIFI_USER
UNIFI_USER=${UNIFI_USER:-homepage}

read -sp "UniFi password: " UNIFI_PASS
echo ""

read -sp "Pi-hole Primary API key: " PIHOLE_PRIMARY
echo ""

read -sp "Pi-hole Secondary API key: " PIHOLE_SECONDARY
echo ""

read -p "Proxmox username [root@pam!homepage]: " PROXMOX_USER
PROXMOX_USER=${PROXMOX_USER:-root@pam!homepage}

read -sp "Proxmox password: " PROXMOX_PASS
echo ""

read -p "Grafana username [admin]: " GRAFANA_USER
GRAFANA_USER=${GRAFANA_USER:-admin}

read -sp "Grafana password: " GRAFANA_PASS
echo ""

cat > "$ENV_FILE" <<EOF
HOMEPAGE_VAR_UNIFI_USERNAME=${UNIFI_USER}
HOMEPAGE_VAR_UNIFI_PASSWORD=${UNIFI_PASS}
HOMEPAGE_VAR_PIHOLE_PRIMARY_KEY=${PIHOLE_PRIMARY}
HOMEPAGE_VAR_PIHOLE_SECONDARY_KEY=${PIHOLE_SECONDARY}
HOMEPAGE_VAR_PROXMOX_USERNAME=${PROXMOX_USER}
HOMEPAGE_VAR_PROXMOX_PASSWORD=${PROXMOX_PASS}
HOMEPAGE_VAR_GRAFANA_USERNAME=${GRAFANA_USER}
HOMEPAGE_VAR_GRAFANA_PASSWORD=${GRAFANA_PASS}
EOF

echo ""
echo ".env file created successfully."
