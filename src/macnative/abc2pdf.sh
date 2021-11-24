#!/bin/sh
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "Usage: ./abc2pdf.sh sessionName homeDir"

./abc2ps.sh $1 $2
OUT=$?

if [ $OUT -eq 0 ];then
    ./ps2pdf.sh $1 $2
    OUT=$?
    
    if [ $OUT -eq 0 ];then
        echo "ABC TO PDF CONVERSION DONE FOR: $1"
    else
	    die "ERROR: ps2pdf.sh failed."
    fi
else
    die "ERROR: abc2ps.sh failed."
fi

