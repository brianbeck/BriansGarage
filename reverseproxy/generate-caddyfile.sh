#!/usr/bin/env bash
set -euo pipefail

# generate-caddyfile.sh
# Portable (macOS bash 3.2 compatible): avoids ${VAR^^} and uses tr for case conversion.
#
# Prompts for:
#  - ACME email
#  - One or more site blocks (domain -> upstream IP:port)
# Optional:
#  - JSON access logging snippet
#  - Catch-all HTTP 404 site
#
# Output: ./Caddyfile (or a path you provide)

to_upper() {
  # macOS bash 3.2 compatible uppercasing
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

prompt_nonempty() {
  # Usage: prompt_nonempty "Prompt text: " VAR_NAME
  # Loops until user provides non-empty input.
  local prompt="$1"
  local __varname="$2"
  local value=""
  while true; do
    read -r -p "$prompt" value
    if [[ -n "$value" ]]; then
      # shellcheck disable=SC2163
      eval "$__varname=\"\$value\""
      return 0
    fi
    echo "Entry can't be empty. Please enter a value."
  done
}

prompt_int_ge_1() {
  # Usage: prompt_int_ge_1 "Prompt text: " VAR_NAME
  local prompt="$1"
  local __varname="$2"
  local value=""
  while true; do
    read -r -p "$prompt" value
    if [[ "$value" =~ ^[0-9]+$ ]] && [[ "$value" -ge 1 ]]; then
      # shellcheck disable=SC2163
      eval "$__varname=\"\$value\""
      return 0
    fi
    echo "Please enter a positive integer (1 or higher)."
  done
}

prompt_yes_no_default_yes() {
  # Usage: prompt_yes_no_default_yes "Question [Y/n]: " VAR_NAME
  # Returns VAR_NAME as "Y" or "N"
  local prompt="$1"
  local __varname="$2"
  local value=""
  while true; do
    read -r -p "$prompt" value
    value="${value:-Y}"
    value="$(to_upper "$value")"
    case "$value" in
      Y|YES)
        # shellcheck disable=SC2163
        eval "$__varname=\"Y\""
        return 0
        ;;
      N|NO)
        # shellcheck disable=SC2163
        eval "$__varname=\"N\""
        return 0
        ;;
      *)
        echo "Please answer Y or N."
        ;;
    esac
  done
}

# ---- Prompts ----

read -r -p "Output Caddyfile path [./Caddyfile]: " OUT_PATH
OUT_PATH="${OUT_PATH:-./Caddyfile}"

prompt_nonempty "ACME email address (for Let's Encrypt / ZeroSSL): " ACME_EMAIL

prompt_int_ge_1 "How many domains/sites do you want to configure? " SITE_COUNT

prompt_yes_no_default_yes "Enable JSON access logging snippet? [Y/n]: " ENABLE_LOGS

LOG_BLOCK=""
IMPORT_LOGS=""
if [[ "$ENABLE_LOGS" == "Y" ]]; then
  read -r -p "Access log path [/var/log/caddy/access.log]: " ACCESS_LOG_PATH
  ACCESS_LOG_PATH="${ACCESS_LOG_PATH:-/var/log/caddy/access.log}"

  LOG_BLOCK=$'\n'"(accesslog) {"$'\n'"    log {"$'\n'"        output file ${ACCESS_LOG_PATH} {"$'\n'"            roll_size 100MiB"$'\n'"            roll_keep 10"$'\n'"            roll_keep_for 720h"$'\n'"        }"$'\n'"        format json"$'\n'"    }"$'\n'"}"$'\n'
  IMPORT_LOGS=$'    import accesslog\n'
fi

prompt_yes_no_default_yes "Include catch-all HTTP 404 site block for unknown hosts? [Y/n]: " INCLUDE_CATCHALL
CATCHALL_BLOCK=""

if [[ "$INCLUDE_CATCHALL" == "Y" ]]; then
  read -r -p "Catch-all web root directory [/var/www]: " CATCHALL_ROOT
  CATCHALL_ROOT="${CATCHALL_ROOT:-/var/www}"
  read -r -p "Catch-all 404 page filename [/404.html]: " CATCHALL_404
  CATCHALL_404="${CATCHALL_404:-/404.html}"

  CATCHALL_BLOCK+=$'\n'"# Catch-all for all *other* HTTP hosts hitting this server"$'\n'
  CATCHALL_BLOCK+="http:// {"$'\n'
  if [[ -n "$IMPORT_LOGS" ]]; then
    CATCHALL_BLOCK+="${IMPORT_LOGS}"
  fi
  CATCHALL_BLOCK+=$'    # Directory where 404.html lives\n'
  CATCHALL_BLOCK+="    root * ${CATCHALL_ROOT}"$'\n\n'
  CATCHALL_BLOCK+=$'    # Force this request into the error handler with status 404\n'
  CATCHALL_BLOCK+=$'    handle {\n'
  CATCHALL_BLOCK+=$'        error 404\n'
  CATCHALL_BLOCK+=$'    }\n\n'
  CATCHALL_BLOCK+=$'    # Serve the 404 page with status 404\n'
  CATCHALL_BLOCK+=$'    handle_errors {\n'
  CATCHALL_BLOCK+="        rewrite * ${CATCHALL_404}"$'\n'
  CATCHALL_BLOCK+=$'        file_server\n'
  CATCHALL_BLOCK+=$'    }\n'
  CATCHALL_BLOCK+=$'}\n'
fi

# ---- Build Caddyfile ----

CADDYFILE_CONTENT="{\n"
CADDYFILE_CONTENT+="    # Optional but recommended for ACME (Let's Encrypt / ZeroSSL)\n"
CADDYFILE_CONTENT+="    email ${ACME_EMAIL}\n"
CADDYFILE_CONTENT+="}\n"

if [[ -n "$LOG_BLOCK" ]]; then
  CADDYFILE_CONTENT+="${LOG_BLOCK}"
fi

for i in $(seq 1 "$SITE_COUNT"); do
  echo ""
  DOMAIN=""
  UPSTREAM=""

  prompt_nonempty "[$i/$SITE_COUNT] Domain (e.g., n8n.example.com): " DOMAIN
  prompt_nonempty "[$i/$SITE_COUNT] Upstream (IP:port, e.g., 192.168.20.208:80): " UPSTREAM

  CADDYFILE_CONTENT+=$'\n'
  CADDYFILE_CONTENT+="# ${DOMAIN} - auto HTTP+HTTPS, with HTTPS certs handled by Caddy"$'\n'
  CADDYFILE_CONTENT+="${DOMAIN} {"$'\n'
  if [[ -n "$IMPORT_LOGS" ]]; then
    CADDYFILE_CONTENT+="${IMPORT_LOGS}"
  fi
  CADDYFILE_CONTENT+="    reverse_proxy ${UPSTREAM} {"$'\n'
  CADDYFILE_CONTENT+='        header_up Host {host}'$'\n'
  CADDYFILE_CONTENT+="    }"$'\n'
  CADDYFILE_CONTENT+="}"$'\n'
done

if [[ -n "$CATCHALL_BLOCK" ]]; then
  CADDYFILE_CONTENT+="${CATCHALL_BLOCK}"
fi

# ---- Write output ----

mkdir -p "$(dirname "$OUT_PATH")"
printf "%b" "$CADDYFILE_CONTENT" > "$OUT_PATH"

echo ""
echo "✅ Generated Caddyfile at: ${OUT_PATH}"
echo ""
echo "Next steps (typical):"
echo "  - Validate:  caddy validate --config ${OUT_PATH}"
echo "  - Reload:    sudo systemctl reload caddy  (or restart if needed)"
