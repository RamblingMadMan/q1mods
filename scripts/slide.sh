#!/bin/bash

MAPS_URL="https://q1mods.xyz/slide/mapdb.json"

echo "--   Downloading '$MAPS_URL'"
wget -c -q --show-progress "$MAPS_URL"
