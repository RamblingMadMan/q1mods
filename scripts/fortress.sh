#!/bin/bash

MAPS_URL="https://q1mods.xyz/fortress/maps.tar.gz"

echo "--   Downloading '$MAPS_URL'"
wget -c -q --show-progress "$MAPS_URL"

tar -xf maps.tar.gz
rm maps.tar.gz
