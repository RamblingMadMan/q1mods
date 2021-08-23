#!/bin/bash

DRAKE_URL="http://quaddicted.com/filebase/drake290111.zip"

echo "--   Downloading '$DRAKE_URL'"
wget -c -q --show-progress "$DRAKE_URL" -O drake.zip

echo "--   Unzipping 'drake290111.zip'"
unzip -L -q drake.zip
rm drake.zip

echo "--   Renaming start map"
mv maps/arcstart.bsp maps/start.bsp
mv maps/arcstart.lit maps/start.lit
