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

# Set Go environment variables needed by other scripts
export GOPATH="/opt/gopath"
export GOROOT="/opt/go"

# ----------------------------------------------------------------
# Install Golang
# ----------------------------------------------------------------
mkdir -p $GOPATH
ARCH=`uname -m | sed 's|i686|386|' | sed 's|x86_64|amd64|'`
BINTARGETS="x86_64 s390x"
GO_VER=1.7.3

# Install Golang binary if found in BINTARGETS
if echo $BINTARGETS | grep -q `uname -m`; then
   cd /tmp
   wget --quiet --no-check-certificate https://storage.googleapis.com/golang/go${GO_VER}.linux-${ARCH}.tar.gz
   tar -xvf go${GO_VER}.linux-${ARCH}.tar.gz
   mv go $GOROOT
   chmod 775 $GOROOT
# else for ppc64le install go binaries from advanced toolchain
elif [ $ARCH = ppc64le ]
then
   wget --quiet ftp://ftp.unicamp.br/pub/linuxpatch/toolchain/at/ubuntu/dists/xenial/at10.0/binary-ppc64el/advance-toolchain-golang-at_10.0-1_ppc64el.deb
   dpkg -i advance-toolchain-golang-at_10.0-1_ppc64el.deb
   rm advance-toolchain-golang-at_10.0-1_ppc64el.deb

   update-alternatives --install /usr/bin/go go /usr/local/go/bin/go 10
   update-alternatives --install /usr/bin/gofmt gofmt /usr/local/go/bin/gofmt 10

   ln -s /usr/local/go $GOROOT
# Otherwise, build Golang from source
else
   # Install Golang 1.6 binary as a bootstrap to compile the Golang GO_VER source
   apt-get -y install golang-1.6

   cd /tmp
   wget --quiet --no-check-certificate https://storage.googleapis.com/golang/go${GO_VER}.src.tar.gz
   tar -xzf go${GO_VER}.src.tar.gz -C /opt

   cd $GOROOT/src
   export GOROOT_BOOTSTRAP="/usr/lib/go-1.6"
   ./make.bash
   apt-get -y remove golang-1.6
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
wget --quiet https://github.com/google/protobuf/archive/$PROTOBUF_PKG
tar xpzf $PROTOBUF_PKG
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

# Make our versioning persistent
echo $BASEIMAGE_RELEASE > /etc/hyperledger-baseimage-release
