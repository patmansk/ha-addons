FROM alpine:3.19

ARG VERSION=3.8.0
ENV RADICALE_VERSION=${VERSION}

RUN addgroup -g 2999 -S radicale && \
    adduser -u 2999 -S -D -G radicale -h /data -s /sbin/nologin radicale

RUN apk add --no-cache python3 py3-pip openssl

RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir radicale==${RADICALE_VERSION}

# Create config directory
RUN mkdir -p /data/collections && \
    chown -R radicale:radicale /data

# Generate default config from environment variables
RUN cat > /usr/local/bin/entrypoint.sh << 'EOF'
#!/bin/sh

# Default values
AUTH_TYPE="${RADICALE_CONFIG_AUTH_TYPE:-none}"
HTPASSWD_FILENAME="${RADICALE_CONFIG_AUTH_HTPASSWD_FILENAME:-/data/users}"
HTPASSWD_ENCRYPTION="${RADICALE_CONFIG_AUTH_HTPASSWD_ENCRYPTION:-bcrypt}"
STORAGE_FOLDER="${RADICALE_CONFIG_STORAGE_FILESYSTEM_FOLDER:-/data/collections}"
SERVER_HOSTS="${RADICALE_CONFIG_SERVER_HOSTS:-0.0.0.0:5232}"

# Ensure storage folder exists
mkdir -p "$STORAGE_FOLDER"
chown -R radicale:radicale /data

# Write config
cat > /tmp/radicale.conf << CONFIG
[server]
hosts = ${SERVER_HOSTS}

[auth]
type = ${AUTH_TYPE}
${AUTH_TYPE:+htpasswd_filename = ${HTPASSWD_FILENAME}}
${AUTH_TYPE:+htpasswd_encryption = ${HTPASSWD_ENCRYPTION}}

[storage]
filesystem_folder = ${STORAGE_FOLDER}

[web]
prefix = /
CONFIG

# If running as radicale user, fix ownership
if [ "$(id -u)" = "2999" ]; then
    chown radicale:radicale /tmp/radicale.conf 2>/dev/null || true
fi

exec /venv/bin/radicale --config /tmp/radicale.conf
EOF
chmod a+x /usr/local/bin/entrypoint.sh

EXPOSE 5232
VOLUME /data
USER radicale
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]