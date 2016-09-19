#!/bin/bash

chgrp -R root /opt/gopath
chmod g+rw /opt/gopath

mkdir /var/hyperledger
chgrp -R root /var/hyperledger
chmod g+rw /var/hyperledger
