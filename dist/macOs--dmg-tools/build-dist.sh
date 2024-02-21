#!/bin/bash

# Check for proper number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 path/to/your.app path/to/background.png"
    exit 1
fi

# Step 1: Get application name
app_folder="$1"
app_name=$(basename "$app_folder" .app)

# Step 2: Patch the .app folder to include icon
./modify_app.sh "$app_folder"

# Step 3: Make a temporary copy of the application icon
cp "$app_folder/Contents/Resources/${app_name}-application-icon.icns" "./${app_name}-application-icon.icns"

# Step 4: Calculate the size of the .app folder and double it to provide a reasonable quota for our virtual disk
size_kb=$(($(./get-dir-size.sh "$app_folder") * 2))

# Step 5: Build the DMG
./make-dmg.sh "$app_folder" "$2" "$app_name" "$size_kb" "./${app_name}-application-icon.icns"

# Step 6: Delete the temporary copy of the application icon
rm "./${app_name}-application-icon.icns"
