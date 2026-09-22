#!/bin/sh
set -e

CONFIG_PATH="/data/options.json"
RADICALE_CONFIG="/tmp/radicale.conf"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

# Fix permissions on /data (we run as root initially)
chown -R radicale:radicale /data 2>/dev/null || true

if [ ! -f "${CONFIG_PATH}" ]; then
    log "FATAL: Options file ${CONFIG_PATH} not found!"
    exit 1
fi

auth_type="$(jq --raw-output '.auth_type // "none"' "${CONFIG_PATH}")"
storage_folder="$(jq --raw-output '.storage_folder // "/data/collections"' "${CONFIG_PATH}")"
log_level="$(jq --raw-output '.log_level // "info"' "${CONFIG_PATH}")"
sharing_type="$(jq --raw-output '.sharing // "none"' "${CONFIG_PATH}")"

log "Starting Radicale add-on..."
log "  Auth type    : ${auth_type}"
log "  Storage      : ${storage_folder}"
log "  Log level    : ${log_level}"
log "  Sharing      : ${sharing_type}"

mkdir -p "${storage_folder}"
chown -R radicale:radicale "${storage_folder}" 2>/dev/null || true

# Generate Radicale config
{
    echo '[server]'
    echo 'hosts = 0.0.0.0:5232'
    echo ''
    echo '[auth]'
    echo "type = ${auth_type}"
    if [ "${auth_type}" = "htpasswd" ]; then
        echo 'htpasswd_filename = /data/users'
        echo 'htpasswd_encryption = bcrypt'
    fi
    echo ''
    echo '[storage]'
    echo "filesystem_folder = ${storage_folder}"
    echo ''
    echo '[logging]'
    echo "level = ${log_level}"
    
    # Add sharing config if enabled
    if [ "${sharing_type}" != "none" ]; then
        echo ''
        echo '[sharing]'
        if [ "${sharing_type}" = "default" ]; then
        echo "type = radicale.sharing.default"
    else
        echo "type = ${sharing_type}"
    fi
        echo "permit_create_token = true"
        echo "permit_create_map = true"
    fi
} > "${RADICALE_CONFIG}"

chown radicale:radicale "${RADICALE_CONFIG}" 2>/dev/null || true

log "Starting Radicale..."
# Drop to non-root user for the actual service
exec su -s /bin/sh radicale -c "exec /venv/bin/radicale --config ${RADICALE_CONFIG}"
