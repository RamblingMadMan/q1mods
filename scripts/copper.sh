#!/bin/bash

UDOB_URL="http://lunaran.com/files/udob_v1_1.zip"

wget -c -q --show-progress "$UDOB_URL" -O udob.zip
unzip -L -q udob.zip
rm udob.zip

