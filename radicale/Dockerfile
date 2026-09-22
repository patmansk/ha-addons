FROM alpine:3.19

ARG VERSION=3.8.0
ENV RADICALE_VERSION=${VERSION}

# Install dependencies
RUN apk add --no-cache python3 py3-pip openssl jq

# Create non-root user
RUN addgroup -g 2999 -S radicale && \
    adduser -u 2999 -S -D -G radicale -h /data -s /sbin/nologin radicale

# Install Radicale in a virtualenv
RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir radicale==${RADICALE_VERSION}

# Prepare data directory
RUN mkdir -p /data/collections && \
    chown -R radicale:radicale /data

# Copy and make run script executable
COPY run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 5232
VOLUME /data

# Run as root initially to fix permissions, then drop to radicale user
# via the run.sh script (using su)
ENTRYPOINT ["/run.sh"]
