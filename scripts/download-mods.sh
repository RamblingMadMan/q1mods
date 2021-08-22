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
	MOD_DESC=$(echo "$MOD_JSON" | jq -r ".desc" | sed 's/"/\\"/g')
	MOD_DIR=$(echo "$MOD_JSON" | jq -r ".dir")
	MOD_LINK=$(echo "$MOD_JSON" | jq -r ".dl")
	ARCHIVE_NAME=${MOD_LINK##*/}

	echo "[Mod] $MOD_NAME"

	if [ ! -f "$MOD_NAME/$ARCHIVE_NAME" ]; then
		echo "-- Downloading '$ARCHIVE_NAME'"
		wget -c -q --show-progress "$MOD_LINK" -O "$MOD_NAME/$ARCHIVE_NAME"
	fi

	if [ ! -f "$MOD_DIR.pak" ]; then
		ARCHIVE_PATH=$(realpath "$MOD_NAME/$ARCHIVE_NAME")

		CURDIR=$(pwd)
		WORKDIR=$(mktemp -d)

		echo "-- Working in temporary dir '${WORKDIR}'"
		cd "$WORKDIR"

		echo "-- Unzipping archive..."
		unzip -L -q "$ARCHIVE_PATH"

		echo "-- Unpacking paks..."
		for pak in pak*.pak
		do
			qpakman -e -f $pak > /dev/null 2>&1
		done

		echo "-- Cleaning up..."
		rm pak*.pak > /dev/null 2>&1
		rm *.txt > /dev/null 2>&1
		rm *.md > /dev/null 2>&1

		if [ -f "$SCRIPT_DIR/$MOD_DIR.sh" ]; then
			echo "-- Running fixes..."
			. "$SCRIPT_DIR/$MOD_DIR.sh"
		fi

		echo "-- Re-packing..."
		qpakman * -o "$MOD_DIR.pak" > /dev/null 2>&1
		mv "$MOD_DIR.pak" "$CURDIR"

		cd $CURDIR
		rm -rf "$WORKDIR"

		echo "-- Packed mod into '${MOD_DIR}.pak'"
	fi

	if [ $i -gt 0 ]; then
		CONTENT_JSON="${CONTENT_JSON},"
	fi

	CONTENT_JSON="${CONTENT_JSON}
		{
			\"name\": \"${MOD_NAME}\",
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
			\"gamedir\": \"${MOD_DIR}\",
			\"download\": \"$MOD_DIR.pak\",
			\"screenshots\": [],
			\"id\": \"$MOD_DIR\"
		}"
done

CONTENT_JSON="$CONTENT_JSON
	]
}"

echo "[Server]"
echo "-- Writing 'content.json'"

echo "$CONTENT_JSON" > content.json
