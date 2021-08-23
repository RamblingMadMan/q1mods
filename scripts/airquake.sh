#!/bin/bash

MAPS_URL="https://q1mods.xyz/airquake/mapdb.json"

echo "--   Downloading '$MAPS_URL'"
wget -c -q --show-progress "$MAPS_URL"
