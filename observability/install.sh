#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Observability Stack Setup ==="
echo
echo "This script creates the secrets files needed by the observability stack."
echo

# Prompt for each secret
read -rp "MinIO Access Key ID: " MINIO_ACCESS_KEY_ID
read -rsp "MinIO Secret Access Key: " MINIO_SECRET_ACCESS_KEY
echo
read -rsp "MinIO Bearer Token (Prometheus JWT): " MINIO_BEARER_TOKEN
echo
echo

# Create .env
cat > "$SCRIPT_DIR/.env" <<EOF
# Loki S3/MinIO credentials (injected into Loki via docker-compose environment)
MINIO_ACCESS_KEY_ID=${MINIO_ACCESS_KEY_ID}
MINIO_SECRET_ACCESS_KEY=${MINIO_SECRET_ACCESS_KEY}

# Prometheus MinIO bearer token (reference copy; actual file is prometheus/secrets/minio_bearer_token)
MINIO_BEARER_TOKEN=${MINIO_BEARER_TOKEN}
EOF
chmod 600 "$SCRIPT_DIR/.env"

# Create Prometheus bearer token file
mkdir -p "$SCRIPT_DIR/prometheus/secrets"
printf '%s' "$MINIO_BEARER_TOKEN" > "$SCRIPT_DIR/prometheus/secrets/minio_bearer_token"
chmod 600 "$SCRIPT_DIR/prometheus/secrets/minio_bearer_token"

echo "Created:"
echo "  .env"
echo "  prometheus/secrets/minio_bearer_token"
echo
echo "You can now start the stack with: docker compose up -d"
