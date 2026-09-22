# This Dockerfile is not used for building - we reference the pre-built image
# from Docker Hub. It's included here for documentation purposes.
#
# Actual image: tomsquest/docker-radicale:3.8.0.0
#
# For reference, the original Dockerfile from tomsquest/docker-radicale:
#
# FROM alpine:3.19
# ARG COMMIT_ID
# ENV COMMIT_ID ${COMMIT_ID}
# ARG VERSION
# ENV VERSION ${VERSION:-3.8.0}
# ARG BUILD_UID
# ENV BUILD_UID ${BUILD_UID:-2999}
# ARG BUILD_GID
# ENV BUILD_GID ${BUILD_GID:-2999}
# ARG TAKE_FILE_OWNERSHIP
# ENV TAKE_FILE_OWNERSHIP ${TAKE_FILE_OWNERSHIP:-true}
#
# RUN addgroup -g $BUILD_GID -S radicale && \
#     adduser -u $BUILD_UID -S -D -G radicale -h /data -s /sbin/nologin radicale
#
# RUN apk add --no-cache python3 py3-pip
#
# RUN python3 -m venv /venv && \
#     /venv/bin/pip install --no-cache-dir radicale==${VERSION}
#
# COPY update_config_from_env.py /usr/local/bin/
# COPY docker-entrypoint.sh /usr/local/bin/
#
# RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
#
# EXPOSE 5232
#
# VOLUME /data
#
# ENTRYPOINT ["docker-entrypoint.sh"]
# CMD ["/venv/bin/radicale", "--config", "/config/config"]

# Placeholder - the actual image is pulled from Docker Hub
FROM alpine:3.19
CMD ["/bin/sh"]