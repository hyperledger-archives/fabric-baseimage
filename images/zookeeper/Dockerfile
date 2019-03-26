# Copyright Greg Haskins All Rights Reserved
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
FROM debian:stretch-slim as download
# Based on https://github.com/31z4/zookeeper-docker/blob/master/3.4.9/Dockerfile
RUN apt-get update \
    && apt-get install -y curl tar git make gcc

# Install su-exec
RUN set -x \
    && git clone https://github.com/ncopa/su-exec /tmp/su-exec/ \
    && cd /tmp/su-exec \
    && make all \
    && cp su-exec /usr/local/bin/

ENV ZOO_USER=zookeeper \
    ZOO_CONF_DIR=/conf

ARG GPG_KEY=C823E3E5B12AF29C67F81976F5CECB3CB5E9BD2D
ARG DISTRO_NAME=zookeeper-3.4.9

# Download Apache Zookeeper, verify its PGP signature, untar and clean up
RUN set -x \
    && mkdir "$ZOO_CONF_DIR" \
    && cd / \
    && curl -fsSL "http://archive.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz" | tar -xz \
    && mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR"


FROM adoptopenjdk/openjdk8-openj9:jre8u212-b04_openj9-0.14.2
ARG DISTRO_NAME=zookeeper-3.4.9
ENV ZOO_USER=zookeeper \
    ZOO_CONF_DIR=/conf \
    ZOO_DATA_DIR=/data \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_PORT=2181 \
    ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2 \
    ZOO_AUTOPURGE_SNAPRETAINCOUNT=3 \
    ZOO_AUTOPURGE_PURGEINTERVAL=1

# Add a user and make dirs
RUN set -x \
    && useradd "$ZOO_USER" \
    && mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" \
    && chown "$ZOO_USER:$ZOO_USER" "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR"

WORKDIR $DISTRO_NAME

VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR"]

EXPOSE $ZOO_PORT 2888 3888

ENV PATH=$PATH:/$DISTRO_NAME/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

COPY --from=download /usr/local/bin /usr/bin
COPY --from=download ${ZOO_CONF_DIR} ${ZOO_CONF_DIR}
COPY --from=download /${DISTRO_NAME} /${DISTRO_NAME}
COPY ./docker-entrypoint.sh /

RUN chown -R "$ZOO_USER:$ZOO_USER" "$ZOO_CONF_DIR"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
