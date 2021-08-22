#!/bin/bash

RUN_SERVER=1

if [ "$#" -eq 1 ]; then
	case "$1" in
		server)
			;;

		setup)
			RUN_SERVER=0
			;;

		*)
			echo "usage: run.sh [server|setup]"
			exit 1
			;;
	esac
elif [ "$#" -gt 1 ]; then
	echo "usage: run.sh [server|setup]"
	exit 1
fi

# arcane wizadry
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

[ -d build ] || ./scripts/build-deps.sh
PATH="$SCRIPT_DIR/build:$PATH"

# create a directory for our server
[ -d q1mods ] || mkdir q1mods
cd q1mods

$SCRIPT_DIR/scripts/download-mods.sh

if [ $RUN_SERVER -eq 1 ]; then
	sudo $SCRIPT_DIR/scripts/start-server.sh
fi
