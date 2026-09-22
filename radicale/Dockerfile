FROM alpine:3.19

ARG VERSION=3.8.0
ENV RADICALE_VERSION=${VERSION}

RUN addgroup -g 2999 -S radicale && \
    adduser -u 2999 -S -D -G radicale -h /data -s /sbin/nologin radicale

RUN apk add --no-cache python3 py3-pip openssl jq

RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir radicale==${RADICALE_VERSION}

# Create config directory
RUN mkdir -p /data/collections && \
    chown -R radicale:radicale /data

COPY run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 5232
VOLUME /data
USER radicale
ENTRYPOINT ["/run.sh"]