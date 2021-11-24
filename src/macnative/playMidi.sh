#!/bin/sh

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./playMidi.sh sessionName homeDir"

# abc2midi adds a trailing `1` char to the file name upon conversion
ls "$2/${1}1.mid" >/dev/null 2>&1 && echo "FOUND file $2/${1}1.mid" || die "File $2/${1}1.mid NOT found"

# fluidynth fails if providing a relative path to a soundfont
pwd=$(pwd)
par=$(dirname $pwd)

fluidsynth -i -n -g 1 "$par/assets/helpers/soundfonts/MAIDENS.SF2" "$2/${1}1.mid"
OUT=$?

# Fluidsynth exits with non zero status if SIGTERM-ed or SIGKILL-ed. From MAIDENS' point of view
# this is wrong, and must be corrected.
if [ $OUT -eq 0 ] || [ $OUT -eq 137 ] || [ $OUT -eq 143 ];then
    echo "PLAYBACK DONE FOR: $1"
else
    die "ERROR: playMidi.sh failed."
fi
