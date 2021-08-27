#!/bin/bash

# arcane wizadry
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MODSFILE=$(cat "../mods.json")

MODS=$(echo "$MODSFILE" | jq '.mods')
NUM_MODS=$(echo "$MODS" | jq 'length')

ADDONS_JSON=""
MOD_EPISODES_JSON=""
MOD_MAPS_JSON=""

# Go through each mod re-packing for the KEX engine

for ((i = 0; i < ${NUM_MODS}; ++i)); do
	MOD_JSON=$(echo "$MODS" | jq ".[$i]")

	MOD_NAME=$(echo "$MOD_JSON" | jq -r ".name")
	MOD_DESC=$(echo "$MOD_JSON" | jq -r ".desc" | sed "s/\"/'/g")
	MOD_DIR=$(echo "$MOD_JSON" | jq -r ".dir")
	MOD_LINK=$(echo "$MOD_JSON" | jq -r ".dl")
	MOD_SCREENS=$(echo "$MOD_JSON" | jq -r ".screens")
	ARCHIVE_NAME=$(echo "${MOD_LINK##*/}" | sed 's/?q1mods=//')

	SCREENS_JSON="["

	echo "[Mod] $MOD_DIR: $MOD_NAME"

	if [ ! -d "$MOD_DIR" ]; then
		echo "-- Creating directory '$MOD_DIR'"
		mkdir -p $MOD_DIR
	fi	

	if [ "null" != "$MOD_SCREENS" ]; then
		NUM_SCREENS=$(echo $MOD_SCREENS | jq 'length')
		echo "-- $NUM_SCREENS screenshots"

		for ((j = 0; j < ${NUM_SCREENS}; ++j)); do
			SCREEN_URL=$(echo "$MOD_SCREENS" | jq -r ".[$j]")
			SCREEN_EXT=${SCREEN_URL##*.}
			SCREEN_OUT="$MOD_DIR/screen$j.${SCREEN_EXT}"

			if [ ! -f "$SCREEN_OUT" ]; then
				echo "--   Downloading '$SCREEN_URL' -> '${SCREEN_OUT}'"
				wget -c -q --show-progress "$SCREEN_URL" -O "$SCREEN_OUT"
			fi

			[ $j -gt 0 ] && SCREENS_JSON="$SCREENS_JSON,"

			SCREENS_JSON="$SCREENS_JSON \"$SCREEN_OUT\""
		done
	fi

	if [ ! -f "$MOD_DIR.pak" ]; then
		if [ ! -f "$MOD_DIR/$ARCHIVE_NAME" ]; then
			echo "-- Downloading '$ARCHIVE_NAME'"
			wget -c -q --show-progress "$MOD_LINK" -O "$MOD_DIR/$ARCHIVE_NAME"
		fi

		ARCHIVE_PATH=$(realpath "$MOD_DIR/$ARCHIVE_NAME")

		CURDIR=$(pwd)
		WORKDIR=$(mktemp -d)

		echo "-- Working in temporary dir '${WORKDIR}'"
		cd "$WORKDIR"

		echo "-- Unzipping archive..."
		unzip -L -q "$ARCHIVE_PATH"

		if [ -d "$MOD_DIR" ]; then
			mv $MOD_DIR/* .
			rm -rf "$MOD_DIR"
		fi

		echo "-- Unpacking paks..."
		for pak in pak*.pak
		do
			echo "--   $pak"
			qpakman -e -f $pak > /dev/null 2>&1
		done

		echo "-- Cleaning up..."
		rm -f *.pak > /dev/null 2>&1
		rm -f *.txt > /dev/null 2>&1
		rm -f *.md > /dev/null 2>&1
		rm -f *.exe > /dev/null 2>&1

		if [ -f "$SCRIPT_DIR/$MOD_DIR.sh" ]; then
			echo "-- Running fixes..."
			. "$SCRIPT_DIR/$MOD_DIR.sh"
		fi

		if [ -d "maps" ]; then
			echo "-- Generating mapdb.json..."
			if [ -f "mapdb.json" ]; then
				echo "--   existing mapdb.json found"
			else
				"$SCRIPT_DIR/generate-mapdb.sh" -n "$MOD_NAME" -d "$MOD_DIR"
				cp mapdb.json "$CURDIR/$MOD_DIR/mapdb.json"
			fi

			if [ $i > 0 ]; then
				MOD_EPISODES_JSON+=","
				MOD_MAPS_JSON+=","
			fi

			EPISODES_JSON=$(cat mapdb.json | jq '.episodes')
			MOD_EPISODES_JSON+="${EPISODES_JSON:1:${#EPISODES_JSON}-2}"

			MAPS_JSON=$(cat mapdb.json | jq '.maps')
			MOD_MAPS_JSON+="${MAPS_JSON:1:${#MAPS_JSON}-2}"
		fi

		echo "-- Re-packing..."
		qpakman * -o "$MOD_DIR.pak" > /dev/null 2>&1
		mv $MOD_DIR.pak "$CURDIR"

		cd $CURDIR
		rm -rf "$WORKDIR"

		echo "-- Packed mod into '${MOD_DIR}.pak'"
	elif [ -f "${MOD_DIR}/mapdb.json" ]; then
		if [ $i > 0 ]; then
                           MOD_EPISODES_JSON+=","
                           MOD_MAPS_JSON+=","
                fi

                EPISODES_JSON=$(cat "${MOD_DIR}/mapdb.json" | jq '.episodes')
                MOD_EPISODES_JSON+="${EPISODES_JSON:1:${#EPISODES_JSON}-2}"

                MAPS_JSON=$(cat "${MOD_DIR}/mapdb.json" | jq '.maps')
                MOD_MAPS_JSON+="${MAPS_JSON:1:${#MAPS_JSON}-2}"
	fi

	SCREENS_JSON="$SCREENS_JSON]"

	ADDON_JSON+=",
		{
			\"name\": \"$MOD_NAME\",
			\"author\": $(echo "$MOD_JSON" | jq '.author'),
			\"date\": $(echo "$MOD_JSON" | jq '.date'),
			\"size\": $(stat --printf="%s" "${MOD_DIR}.pak"),
			\"description\": {
				\"fr\": \"$MOD_DESC\",
				\"it\": \"$MOD_DESC\",
				\"de\": \"$MOD_DESC\",
				\"en\": \"$MOD_DESC\",
				\"es\": \"$MOD_DESC\",
				\"ru\": \"$MOD_DESC\"
			},
			\"gamedir\": \"$MOD_DIR\",
			\"download\": \"$MOD_DIR.pak\",
			\"screenshots\": $SCREENS_JSON,
			\"id\": \"$MOD_DIR\"
		}"
done

ID1_MAPDB_URL="https://q1mods.xyz/id1/mapdb.json.orig"

echo "Downloading original mapdb.json"
wget -c -q --show-progress "$ID1_MAPDB_URL"

ID1_EPISODES_JSON=$(cat mapdb.json.orig | jq '.episodes')
ID1_MAPS_JSON=$(cat mapdb.json.orig | jq '.maps')

ALL_MAPDB_JSON="{
	\"episodes\": [
		${ID1_EPISODES_JSON:1:${#ID1_EPISODES_JSON}-2} $MOD_EPISODES_JSON
	],
	\"maps\": [
		${ID1_MAPS_JSON:1:${#ID1_MAPS_JSON}-2} $MOD_MAPS_JSON
	]
}"

echo "[Server]"

echo "-- Writing id1 override 'mapdb.json'"
echo "$ALL_MAPDB_JSON" > mapdb.json

echo "-- Packing 'id1.pak'"
qpakman mapdb.json -o id1.pak > /dev/null 2>&1

OVERRIDE_DESC="This add-on gives you access to all of the installed mods in this list from the multiplayer menu.

HOW TO ENABLE
=============

1. Download this add-on
2. Activate another add-on
3. Activate this add-on again
4. ???
5. Fragging."

CONTENT_JSON="{
	\"addons\": [
		{
			\"name\": \"Multiplayer id1 Override\",
			\"author\": \"q1mods.xyz\",
			\"date\": \"$(date +"%D")\",
			\"size\": $(stat --printf="%s" "id1.pak"),
			\"description\": {
				\"fr\": \"$OVERRIDE_DESC\",
				\"it\": \"$OVERRIDE_DESC\",
				\"de\": \"$OVERRIDE_DESC\",
				\"en\": \"$OVERRIDE_DESC\",
				\"es\": \"$OVERRIDE_DESC\",
				\"ru\": \"$OVERRIDE_DESC\"
			},
			\"gamedir\": \"id1\",
			\"download\": \"id1.pak\",
			\"screenshots\": [],
			\"id\": \"id1\"
		}$ADDON_JSON
	]
}"

echo "-- Writing 'content.json'"
echo "$CONTENT_JSON" > content.json

