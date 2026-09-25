#!/bin/sh
set -e

CONFIG_PATH="/data/options.json"
RADICALE_CONFIG="/tmp/radicale.conf"
RADICALE_DATA="/data"

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
sharing_enabled="$(jq --raw-output '.sharing // true' "${CONFIG_PATH}")"
# Radicale 3.8.1 natively supports conversion_bday within the [sharing] section
bday_summary_template="$(jq --raw-output '.bday_summary_template // "[{n:f} {n:g}|{fn}|{nickname}] ({year}) (BDAY)"' "${CONFIG_PATH}")"
bday_description_template="$(jq --raw-output '.bday_description_template // "BDAY={year}-{month}-{day}"' "${CONFIG_PATH}")"
bday_alarm_trigger_template="$(jq --raw-output '.bday_alarm_trigger_template // ""' "${CONFIG_PATH}")"
bday_categories="$(jq --raw-output '.bday_categories // "Birthday"' "${CONFIG_PATH}")"
bday_age_max="$(jq --raw-output '.bday_age_max // 99' "${CONFIG_PATH}")"

log "Starting Radicale add-on..."
log "  Auth type    : ${auth_type}"
log "  Storage      : ${storage_folder}"
log "  Log level    : ${log_level}"
log "  Sharing      : ${sharing_enabled} (using CSV backend)"

mkdir -p "${storage_folder}"
mkdir -p "${RADICALE_DATA}/collection-db"
chown -R radicale:radicale "${storage_folder}" 2>/dev/null || true
chown -R radicale:radicale "${RADICALE_DATA}/collection-db" 2>/dev/null || true

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
    echo ''
    echo '[rights]'
    echo 'type = radicale.rights.authenticated'
    echo ''
    echo '[sharing]'
    echo 'type = csv'
    echo 'collection_by_token = true'
    echo 'permit_create_token = true'
    echo 'collection_by_map = true'
    echo 'permit_create_map = true'
    echo "database_path = ${RADICALE_DATA}/collection-db/sharing.csv"
    echo "conversion_bday_summary_template = ${bday_summary_template}"
    echo "conversion_bday_description_template = ${bday_description_template}"
    echo "conversion_bday_alarm_trigger_template = ${bday_alarm_trigger_template}"
    echo "conversion_bday_categories = ${bday_categories}"
    echo "conversion_bday_age_max = ${bday_age_max}"
    echo ''
    echo '[web]'
    echo 'type = internal'
} > "${RADICALE_CONFIG}"

log "Generated configuration:"
cat "${RADICALE_CONFIG}"

chown radicale:radicale "${RADICALE_CONFIG}" 2>/dev/null || true

log "Starting Radicale..."
# Drop to non-root user for the actual service
exec su -s /bin/sh radicale -c "exec /venv/bin/radicale --config ${RADICALE_CONFIG}"
