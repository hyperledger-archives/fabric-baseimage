#!/bin/bash
#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Stop on first error
set -e
set -x

ARCH=`uname -m | sed 's|i686|386|' | sed 's|x86_64|amd64|'`

# ----------------------------------------------------------------
# Install JDK 1.8
# ----------------------------------------------------------------
if [ $ARCH = s390x -o $ARCH = ppc64le ]; then
    # Java is required for node.bin below. InstallAnywhere requirement.
    # See https://github.com/ibmruntimes/ci.docker/blob/master/ibmjava/8-sdk/s390x/ubuntu/Dockerfile
    JAVA_VERSION=1.8.0_sr3fp12
    ESUM_s390x="46766ac01bc2b7d2f3814b6b1561e2d06c7d92862192b313af6e2f77ce86d849"
    ESUM_ppc64le="6fb86f2188562a56d4f5621a272e2cab1ec3d61a13b80dec9dc958e9568d9892"
    eval ESUM=\$ESUM_$ARCH
    BASE_URL="https://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/meta/"
    YML_FILE="sdk/linux/$ARCH/index.yml"
    wget -q -U UA_IBM_JAVA_Docker -O /tmp/index.yml $BASE_URL/$YML_FILE
    JAVA_URL=$(cat /tmp/index.yml | sed -n '/'$JAVA_VERSION'/{n;p}' | sed -n 's/\s*uri:\s//p' | tr -d '\r')
    wget -q -U UA_IBM_JAVA_Docker -O /tmp/ibm-java.bin $JAVA_URL
    echo "$ESUM  /tmp/ibm-java.bin" | sha256sum -c -
    echo "INSTALLER_UI=silent" > /tmp/response.properties
    echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties
    echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties
    mkdir -p /opt/ibm
    chmod +x /tmp/ibm-java.bin
    /tmp/ibm-java.bin -i silent -f /tmp/response.properties
    ln -s /opt/ibm/java/jre/bin/* /usr/local/bin/
else
    apt-get update && apt-get install openjdk-8-jdk -y
fi
