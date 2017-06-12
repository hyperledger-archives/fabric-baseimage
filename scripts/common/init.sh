#!/bin/bash
#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Update the entire system to the latest releases
apt-get -qq update
apt-get dist-upgrade -qqy
