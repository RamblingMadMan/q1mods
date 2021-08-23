#!/bin/bash

MAPS_URL="https://q1mods.xyz/kickflip/mapdb.json"

echo "--   Downloading '$MAPS_URL'"
wget -c -q --show-progress "$MAPS_URL"

mv maps/kfqstart.bsp maps/start.bsp
