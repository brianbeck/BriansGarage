# Homepage Dashboard

A [Homepage](https://gethomepage.dev/) dashboard configuration for monitoring home network services and infrastructure.

## Services

- **Networking** — EdgeOS Router, UniFi, Pi-hole (primary & secondary), Proxmox
- **Services** — Google Workspace, Trello, MinIO, Prometheus, Loki
- **Observability** — Grafana
- **Tools** — n8n

## Prerequisites

- Docker and Docker Compose
- Access credentials for the services listed above

## Installation

1. Clone the repository:

   ```bash
   git clone <repo-url>
   cd homepage
   ```

2. Run the install script to create the `.env` file with your service credentials:

   ```bash
   ./install.sh
   ```

   The script will prompt you for:

   | Secret | Default |
   |--------|---------|
   | UniFi username | `homepage` |
   | UniFi password | — |
   | Pi-hole Primary API key | — |
   | Pi-hole Secondary API key | — |
   | Proxmox username | `root@pam!homepage` |
   | Proxmox password | — |
   | Grafana username | `admin` |
   | Grafana password | — |

   Passwords and API keys are entered silently (not echoed to the terminal).

3. Start the container:

   ```bash
   docker compose up -d
   ```

   The dashboard will be available on port **3500**.

## Configuration

- `config/services.yaml` — Service definitions and widget configuration
- `config/settings.yaml` — Homepage settings
- `config/widgets.yaml` — Global widget configuration
- `docker-compose.yml` — Container configuration

Secrets are referenced in the config files using `{{HOMEPAGE_VAR_*}}` syntax and resolved from the `.env` file at runtime. The `.env` file is excluded from version control via `.gitignore`.
