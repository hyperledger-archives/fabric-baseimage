#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
FROM _NS_/fabric-baseos:_TAG_
COPY scripts /tmp/scripts
RUN cd /tmp/scripts && \
    common/jvm.sh && \
    common/cleanup.sh && \
    rm -rf /tmp/scripts
