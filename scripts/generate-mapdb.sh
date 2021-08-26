#!/bin/bash

# Generate mapdb.json file needed for multiplayer
# run this script from the mod directory

function show_help(){
	echo "Usage: generate-mapdb.sh [-n \"Mod Name\"] [-d \"moddir\"]"
}

MOD_DIR=$(basename $(pwd))
MOD_NAME=$MOD_DIR

while [[ $# -gt 0 ]]; do
	ARG="$1"

	case "$ARG" in
		-n)
			shift
			MOD_NAME="$1"
			shift
			;;

		-d)
			shift
			MOD_DIR="$!"
			shift
			;;

		*)
			echo "Bad argument \"$ARG\""
			show_help
			exit 1
			;;
	esac
done

MAP_JSON="{
	\"episodes\": [
		{
			\"dir\": \"$MOD_DIR\",
			\"name\": \"$MOD_NAME\"
		}
	],
	\"maps\": ["

MAPS=$(ls -1 maps/*.bsp)

IFS=$'\n'
for MAP_PATH in $(echo "$MAPS"); do
	MAP_BSP=$(basename -- "${MAP_PATH%.*}")
	MAP_TITLE="$MAP_BSP"

	MAP_JSON="$MAP_JSON
		{
			\"title\": \"$MAP_BSP\",
			\"bsp\": \"$MAP_BSP\",
			\"episode\": \"$MOD_DIR\",
			\"game\": \"$MOD_DIR\",
			\"dm\": true,
			\"coop\": true,
			\"bots\": true,
			\"sp\": true
		},"
done

# del last comma ^ from string then delimit json
MAP_JSON="${MAP_JSON::-1}
	]
}"

echo "$MAP_JSON" > mapdb.json

