#!/bin/bash
#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
chgrp -R root /opt/gopath
chmod g+rw /opt/gopath

mkdir /var/hyperledger
chgrp -R root /var/hyperledger
chmod g+rw /var/hyperledger
