#!/bin/bash

# arcane wizadry
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MODSFILE=$(cat "../mods.json")

MODS=$(echo "$MODSFILE" | jq '.mods')
NUM_MODS=$(echo "$MODS" | jq 'length')

CONTENT_JSON="{
	\"addons\": ["

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

	echo "[Mod] $MOD_NAME"

	if [ ! -d "$MOD_DIR" ]; then
		echo "-- Creating directory '$MOD_DIR'"
		mkdir -p $MOD_DIR
	fi

	if [ ! -f "$MOD_DIR/$ARCHIVE_NAME" ]; then
		echo "-- Downloading '$ARCHIVE_NAME'"
		wget -c -q --show-progress "$MOD_LINK" -O "$MOD_DIR/$ARCHIVE_NAME"
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
		ARCHIVE_PATH=$(realpath "$MOD_DIR/$ARCHIVE_NAME")

		CURDIR=$(pwd)
		WORKDIR=$(mktemp -d)

		echo "-- Working in temporary dir '${WORKDIR}'"
		cd "$WORKDIR"

		echo "-- Unzipping archive..."
		unzip -L -q "$ARCHIVE_PATH"

		if [ ! -z "$(ls | grep $MOD_DIR)" ]; then
			mv $MOD_DIR/* .
			rm -rf "$MOD_DIR"
		fi

		if [ -f "$SCRIPT_DIR/$MOD_DIR.sh" ]; then
			echo "-- Running fixes..."
			. "$SCRIPT_DIR/$MOD_DIR.sh"
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

		echo "-- Re-packing..."
		qpakman * -o "$MOD_DIR.pak" > /dev/null 2>&1
		mv "$MOD_DIR.pak" "$CURDIR"

		cd $CURDIR
		rm -rf "$WORKDIR"

		echo "-- Packed mod into '${MOD_DIR}.pak'"
	fi

	SCREENS_JSON="$SCREENS_JSON]"

	if [ $i -gt 0 ]; then
		CONTENT_JSON="${CONTENT_JSON},"
	fi

	CONTENT_JSON="${CONTENT_JSON}
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

CONTENT_JSON="$CONTENT_JSON
	]
}"

echo "[Server]"
echo "-- Writing 'content.json'"

echo "$CONTENT_JSON" > content.json
