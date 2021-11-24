#!/bin/sh

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "Usage: ./stopMidi.sh sessionName"

killall -15 fluidsynth
OUT=$?

if [ $OUT -eq 0 ];then
    echo "MIDI PLAYBACK STOPPED FOR: $1"
else
    echo "ERROR: stopMidi.sh failed."
fi
