#!/bin/bash
set -e

CONFIG_PATH="/data/options.json"
RADICALE_CONFIG="/tmp/radicale.conf"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

if [ ! -f "${CONFIG_PATH}" ]; then
    log "FATAL: Options file ${CONFIG_PATH} not found!"
    exit 1
fi

auth_type="$(jq --raw-output '.RADICALE_CONFIG_AUTH_TYPE // "none"' "${CONFIG_PATH}")"
htpasswd_filename="$(jq --raw-output '.RADICALE_CONFIG_AUTH_HTPASSWD_FILENAME // "/data/users"' "${CONFIG_PATH}")"
htpasswd_encryption="$(jq --raw-output '.RADICALE_CONFIG_AUTH_HTPASSWD_ENCRYPTION // "bcrypt"' "${CONFIG_PATH}")"
storage_folder="$(jq --raw-output '.RADICALE_CONFIG_STORAGE_FILESYSTEM_FOLDER // "/data/collections"' "${CONFIG_PATH}")"
server_hosts="$(jq --raw-output '.RADICALE_CONFIG_SERVER_HOSTS // "0.0.0.0:5232"' "${CONFIG_PATH}")"

log "Starting Radicale add-on..."
log "  Auth type    : ${auth_type}"
log "  Storage      : ${storage_folder}"
log "  Server hosts : ${server_hosts}"

mkdir -p "${storage_folder}"

if [ "${auth_type}" = "htpasswd" ]; then
    log "Using htpasswd auth: ${htpasswd_filename}"
fi

{
    echo '[server]'
    echo "hosts = ${server_hosts}"
    echo ''
    echo '[auth]'
    echo "type = ${auth_type}"
    if [ "${auth_type}" = "htpasswd" ]; then
        echo "htpasswd_filename = ${htpasswd_filename}"
        echo "htpasswd_encryption = ${htpasswd_encryption}"
    fi
    echo ''
    echo '[storage]'
    echo "filesystem_folder = ${storage_folder}"
    echo ''
    echo '[web]'
    echo 'prefix = /'
} > "${RADICALE_CONFIG}"

log "Starting Radicale..."
exec /venv/bin/radicale --config "${RADICALE_CONFIG}"
