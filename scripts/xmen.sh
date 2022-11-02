#!/bin/bash

MUSIC_ZIP="xmen_music_flac.zip"
MUSIC_URL="https://www.quaddicted.com/files/music/$MUSIC_ZIP"

echo "--   Downloading '$MUSIC_URL'"
wget -c -q --show-progress "$MUSIC_URL"

mkdir -p music
pushd music

unzip "../$MUSIC_ZIP"

for track in *.flac; do
	output_name=$(echo "$track" | sed -E 's/track00([0-9]).flac/track0\1.ogg/')
	echo "Input:  $track"
	echo "Output: $output_name"
	ffmpeg -i "$track" "$output_name"
	rm "$track"
done

popd

rm "$MUSIC_ZIP"
