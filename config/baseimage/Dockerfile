#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
FROM adoptopenjdk:8u222-b10-jdk-openj9-0.15.1
COPY scripts /tmp/scripts
RUN cd /tmp/scripts && \
    common/packages.sh && \
    common/setup.sh && \
    docker/fixup.sh && \
    common/cleanup.sh && \
    rm -rf /tmp/scripts
ENV GOPATH=/opt/gopath
ENV GOROOT=/opt/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin
