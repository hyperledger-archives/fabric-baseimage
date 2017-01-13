#!/bin/bash

set -e

# clean up our environment
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
