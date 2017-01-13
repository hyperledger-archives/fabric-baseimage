#!/bin/bash

# Update the entire system to the latest releases
apt-get -qq update
apt-get dist-upgrade -qqy
