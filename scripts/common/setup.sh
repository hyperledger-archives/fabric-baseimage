#!/bin/bash

# ALERT: if you encounter an error like:
# error: [Errno 1] Operation not permitted: 'cf_update.egg-info/requires.txt'
# The proper fix is to remove any "root" owned directories under your update-cli directory
# as source mount-points only work for directories owned by the user running vagrant

# Stop on first error
set -e
set -x

# Update the entire system to the latest releases
apt-get update -qq
apt-get dist-upgrade -qqy

# install common tools
apt-get install --yes git net-tools netcat-openbsd

MACHINE=`uname -m`

# Set Go environment variables needed by other scripts
export GOPATH="/opt/gopath"

# ----------------------------------------------------------------
# Install Golang
# ----------------------------------------------------------------
mkdir -p $GOPATH
if [ x$MACHINE = xppc64le ]
then
   wget ftp://ftp.unicamp.br/pub/linuxpatch/toolchain/at/ubuntu/dists/trusty/at9.0/binary-ppc64el/advance-toolchain-at9.0-golang_9.0-3_ppc64el.deb
   dpkg -i advance-toolchain-at9.0-golang_9.0-3_ppc64el.deb
   rm advance-toolchain-at9.0-golang_9.0-3_ppc64el.deb

   update-alternatives --install /usr/bin/go go /usr/local/go/bin/go 9
   update-alternatives --install /usr/bin/gofmt gofmt /usr/local/go/bin/gofmt 9

   export GOROOT="/usr/local/go"
else
   export GOROOT="/opt/go"

   ARCH=`uname -m | sed 's|i686|386|' | sed 's|x86_64|amd64|'`
   GO_VER=1.7.1

   cd /tmp
   wget --quiet --no-check-certificate https://storage.googleapis.com/golang/go$GO_VER.linux-${ARCH}.tar.gz
   tar -xvf go$GO_VER.linux-${ARCH}.tar.gz
   mv go $GOROOT
   chmod 775 $GOROOT
   rm go$GO_VER.linux-${ARCH}.tar.gz
fi

PATH=$GOROOT/bin:$GOPATH/bin:$PATH

cat <<EOF >/etc/profile.d/goroot.sh
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin:$GOPATH/bin
EOF


# ----------------------------------------------------------------
# Install NodeJS
# ----------------------------------------------------------------
NODE_VER=6.7.0

ARCH=`uname -m | sed 's|i686|x86|' | sed 's|x86_64|x64|'`
NODE_PKG=node-v$NODE_VER-linux-$ARCH.tar.gz
SRC_PATH=/tmp/$NODE_PKG

# First remove any prior packages downloaded in case of failure
cd /tmp
rm -f node*.tar.gz
wget --quiet https://nodejs.org/dist/v$NODE_VER/$NODE_PKG
cd /usr/local && sudo tar --strip-components 1 -xzf $SRC_PATH

# ----------------------------------------------------------------
# Install protocol buffer support
#
# See https://github.com/google/protobuf
# ----------------------------------------------------------------
PROTOBUF_VER=3.1.0
PROTOBUF_PKG=v$PROTOBUF_VER.tar.gz

cd /tmp
if [ x$MACHINE = xs390x ]
then
    git clone -b $PROTOBUF_VER https://github.com/linux-on-ibm-z/protobuf.git protobuf-$PROTOBUF_VER
else
    wget --quiet https://github.com/google/protobuf/archive/$PROTOBUF_PKG
    tar xpzf $PROTOBUF_PKG
fi
cd protobuf-$PROTOBUF_VER
apt-get install -y autoconf automake libtool curl make g++ unzip
apt-get install -y build-essential
./autogen.sh
# NOTE: By default, the package will be installed to /usr/local. However, on many platforms, /usr/local/lib is not part of LD_LIBRARY_PATH.
# You can add it, but it may be easier to just install to /usr instead.
#
# To do this, invoke configure as follows:
#
# ./configure --prefix=/usr
#
#./configure
./configure --prefix=/usr

make
make check
make install
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
cd ~/

# ----------------------------------------------------------------
# Install rocksdb
# ----------------------------------------------------------------
apt-get install -y libsnappy-dev zlib1g-dev libbz2-dev
cd /tmp
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
git checkout tags/v4.1
if [ x$MACHINE = xs390x ]
then
    echo There were some bugs in 4.1 for z/p, dev stream has the fix, living dangereously, fixing in place
    sed -i -e "s/-march=native/-march=z196/" build_tools/build_detect_platform
    sed -i -e "s/-momit-leaf-frame-pointer/-DDUMBDUMMY/" Makefile
elif [ x$MACHINE = xppc64le ]
then
    echo There were some bugs in 4.1 for z/p, dev stream has the fix, living dangereously, fixing in place.
    echo Below changes are not required for newer releases of rocksdb.
    sed -ibak 's/ifneq ($(MACHINE),ppc64)/ifeq (,$(findstring ppc64,$(MACHINE)))/g' Makefile
fi

PORTABLE=1 make shared_lib
INSTALL_PATH=/usr/local make install-shared
ldconfig
cd ~/

# ----------------------------------------------------------------
# Install JDK 1.8
# ----------------------------------------------------------------
apt-get update && apt-get install openjdk-8-jdk -y

# Make our versioning persistent
echo $BASEIMAGE_RELEASE > /etc/hyperledger-baseimage-release

# clean up our environment
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
