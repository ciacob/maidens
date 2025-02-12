#!/bin/bash

# Check for proper number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: ./get-dir-size.sh directory"
    exit 1
fi

dir="$1"

# Check if the provided path is a directory
if [ ! -d "$dir" ]; then
    echo "Error: '$dir' is not a directory."
    exit 1
fi

# Calculate the size of the directory in kilobytes and print only the size
du -sk "$dir" | cut -f1
