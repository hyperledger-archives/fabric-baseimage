#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
FROM adoptopenjdk/openjdk8-openj9:jdk8u212-b04_openj9-0.14.2
COPY scripts /tmp/scripts
RUN cd /tmp/scripts && \
    common/packages.sh && \
    common/setup.sh && \
    docker/fixup.sh && \
    common/cleanup.sh && \
    rm -rf /tmp/scripts
ENV GOPATH=/opt/gopath
ENV GOROOT=/opt/go
ENV GOCACHE=off
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin
