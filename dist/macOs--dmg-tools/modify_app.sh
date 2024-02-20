#!/bin/bash

# Check for proper number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/your.app"
    exit 1
fi

app_folder="$1"

# Extract application name
app_name=$(basename "$app_folder" .app)

# Check if Info.plist exists
plist_file="$app_folder/Contents/Info.plist"
if [ ! -f "$plist_file" ]; then
    echo "Error: Info.plist not found in $app_folder"
    exit 1
fi

# Copy icon file to the Resources directory
icon_file_src="$app_folder/Contents/Resources/assets/images/${app_name}-application-icon.icns"
icon_file_dst="$app_folder/Contents/Resources/${app_name}-application-icon.icns"
if [ -f "$icon_file_src" ]; then
    cp "$icon_file_src" "$icon_file_dst"
else
    echo "Error: Icon file not found in $icon_file_src"
    exit 1
fi

# Modify Info.plist to include CFBundleIconFile
icon_string="<key>CFBundleIconFile</key>\n\t<string>${app_name}-application-icon.icns</string>"
sed -i '' "s|</dict>|${icon_string}\n\t</dict>|" "$plist_file"

echo "Icon file copied and Info.plist modified successfully."
