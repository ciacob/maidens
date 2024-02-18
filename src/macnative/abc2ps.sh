#!/bin/sh
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./abc2ps.sh sessionName homeDir"

ls "$2/$1.abc" >/dev/null 2>&1 && echo "FOUND file $2/$1.abc" || die "File $2/$1.abc NOT found"

./abcm2ps -N3 -c "$2"/"$1".abc -O "$2"/"$1".ps
OUT=$?

if [ $OUT -eq 0 ];then
	echo "ABC CONVERSION DONE FOR: $1"
else
    echo "ERROR: abc2ps.sh failed."
fi
