# Copyright Greg Haskins All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
FROM _BASE_NS_/fabric-baseimage:_BASE_TAG_

ENV SCALA_VERSION=2.11 \
    KAFKA_VERSION=1.0.0 \
    KAFKA_DOWNLOAD_SHA1=04A88D7B9830E99841A13EC97809E58D0691D185

RUN curl -fSL "http://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" -o kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    && echo "${KAFKA_DOWNLOAD_SHA1}  kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" | sha1sum -c - \
    && tar xfz kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt \
    && mv /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION" /opt/kafka \
    && rm kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

ADD payload/kafka-run-class.sh /opt/kafka/bin/kafka-run-class.sh

ADD payload/docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 9092
EXPOSE 9093

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/kafka/bin/kafka-server-start.sh"]
