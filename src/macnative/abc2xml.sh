#!/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}


[ "$#" -eq 2 ] || die "Usage: ./abc2xml.sh sessionName homeDir"

ls "$2/$1.abc" >/dev/null 2>&1 && echo "FOUND file $2/$1.abc" || die "File $2/$1.abc NOT found"

python2 ./abc2xml.py "$2/$1.abc" -o "$2"
OUT=$?

if [ $OUT -eq 0 ];then
    echo "ABC TO XML CONVERSION DONE FOR: $1"
else
    die "ERROR: abc2xml.sh failed."
fi