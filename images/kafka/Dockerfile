# Copyright Greg Haskins All Rights Reserved
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
FROM debian:buster-20190910-slim as download
RUN apt-get update \
    && apt-get install -y curl \
    tar \
    gnupg;

ENV SCALA_VERSION=2.11 \
    KAFKA_VERSION=1.0.2 \
    KAFKA_DOWNLOAD_SHA1=4B56E63F9E5E69BCAA0E15313F75F1B15F6CF1E4

RUN curl -fSL "http://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" -o kafka.tgz

RUN echo "${KAFKA_DOWNLOAD_SHA1}  kafka.tgz" | sha1sum -c - \
    && mkdir /opt/kafka \
    && tar xfz kafka.tgz -C /opt/kafka --strip-components=1 \
    && rm -f kafka.tgz;

FROM adoptopenjdk:8u222-b10-jre-openj9-0.15.1
COPY --from=download /opt/kafka /opt/kafka
ADD ./kafka-run-class.sh /opt/kafka/bin/kafka-run-class.sh
ADD ./docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 9092
EXPOSE 9093

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/kafka/bin/kafka-server-start.sh"]
