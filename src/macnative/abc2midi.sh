#!/bin/sh
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./abc2midi.sh sessionName homeDir"

ls "$2/$1.abc" >/dev/null 2>&1 && echo "FOUND file $2/$1.abc" || die "File $2/$1.abc NOT found"

./abc2midi "$2/$1.abc" 1 -o"$2/$1.mid"
OUT=$?

if [ $OUT -eq 0 ];then
    echo "MIDI CONVERSION DONE FOR: $1"
else
    die "ERROR: abc2midi.sh failed."
fi

