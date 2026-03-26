# Observability Stack

A Docker Compose-based observability stack for monitoring and log aggregation, designed to run on a Synology NAS.

## Components

| Service | Description | Port |
|---|---|---|
| **Prometheus** | Metrics collection and time-series database. Scrapes its own metrics and a MinIO cluster. | `9890` |
| **Loki** | Log aggregation engine. Stores log data in MinIO (S3-compatible) object storage with TSDB indexing and 30-day retention. | `3100` |
| **Grafana** | Visualization and dashboarding. Pre-provisioned with Loki as the default datasource. | `3000` |
| **Promtail** | Log shipping agent. Tails Synology system logs and forwards them to Loki. | -- |

## Prerequisites

- Docker and Docker Compose
- Network access to your MinIO instance
- MinIO credentials (access key, secret key, and a Prometheus bearer token)

## Setup

### 1. Configure secrets

Run the install script to create the required secrets files:

```sh
./install.sh
```

You will be prompted for three values:

- **MinIO Access Key ID** -- used by Loki to read/write log data to S3
- **MinIO Secret Access Key** -- the corresponding secret for the access key
- **MinIO Bearer Token** -- a JWT used by Prometheus to scrape MinIO metrics

The script creates:

- `.env` -- environment variables consumed by Docker Compose and passed to Loki
- `prometheus/secrets/minio_bearer_token` -- token file read by Prometheus at runtime

Both files are excluded from version control via `.gitignore`.

### 2. Start the stack

```sh
docker compose up -d
```

### 3. Access the services

- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9890
- **Loki** (API): http://localhost:3100

## Project Structure

```
.
├── docker-compose.yml
├── install.sh
├── .env                          # created by install.sh (gitignored)
├── grafana/
│   ├── data/                     # Grafana persistent data and plugins
│   └── provisioning/
│       └── datasources/
│           └── datasources.yaml  # auto-provisions Loki as a datasource
├── loki/
│   ├── config/
│   │   └── loki-config.yaml
│   └── data/                     # Loki WAL, index, and cache
├── prometheus/
│   ├── config/
│   │   └── prometheus.yml
│   └── secrets/                  # created by install.sh (gitignored)
│       └── minio_bearer_token
└── promtail/
    ├── config/
    │   └── promtail-config.yaml
    └── data/                     # Promtail position tracking
```

## How Secrets Are Managed

Secrets are kept out of version control and injected at runtime:

- **Loki** receives MinIO credentials as environment variables via Docker Compose. The Loki config references them as `${MINIO_ACCESS_KEY_ID}` and `${MINIO_SECRET_ACCESS_KEY}`, expanded at startup with the `-config.expand-env=true` flag.
- **Prometheus** reads its MinIO bearer token from a file mounted into the container at `/etc/prometheus/secrets/minio_bearer_token`, using the `bearer_token_file` directive.

To rotate secrets, re-run `./install.sh` and restart the stack.
