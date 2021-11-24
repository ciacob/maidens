#!/bin/sh

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./midi2wav.sh sessionName homeDir"

ls "$2/${1}.mid" >/dev/null 2>&1 && echo "FOUND file $2/${1}.mid" || die "File $2/${1}.mid NOT found"

# fluidynth fails if providing a relative path to a soundfont
pwd=$(pwd)
par=$(dirname $pwd)

fluidsynth -i -n -g 1 -F "$2/$1.wav" "$par/assets/helpers/soundfonts/MAIDENS.SF2" "$2/${1}.mid"
OUT=$?

if [ $OUT -eq 0 ];then
    echo "RECORDING TO WAV DONE FOR: $1"
else
    echo "ERROR: midi2wav.sh failed."
fi

