#!/bin/bash

QRC_URL="https://q1mods.xyz/rally/quake.rc"
MAPS_URL="https://q1mods.xyz/rally/mapdb.json"

#echo "--   Downloading '$QRC_URL'"
#wget -c -q --show-progress "$QRC_URL"

echo "--   Downloading '$MAPS_URL'"
wget -c -q --show-progress "$MAPS_URL"
