#!/bin/sh

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./ps2png.sh sessionName homeDir"

ls "$2/$1.ps" >/dev/null 2>&1 && echo "FOUND file $2/$1.ps" || die "File $2/$1.ps NOT found"

gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -r600 -sOutputFile="$2/$1.pdf" "$2/$1.ps"
OUT=$?

if [ $OUT -eq 0 ];then
    echo "PS CONVERSION DONE FOR: $1"
else
    die "ERROR: ps2pdf.sh failed."
fi

