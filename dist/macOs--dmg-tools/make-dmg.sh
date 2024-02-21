#!/bin/sh

die () {
    echo >&2 "$@"
    exit 1
}

# Check for proper number of args
[ "$#" -eq 5 ] || die "Usage: ./make-dmg.sh source-folder background-picture title size-in-kb icon"

# Check if both source folder, background-image and icon exist
ls "$1" >/dev/null 2>&1 && echo "FOUND source folder $1" || die "Source folder $1 NOT found"
ls "$2" >/dev/null 2>&1 && echo "FOUND background picture $2" || die "Background picture $2 NOT found"
ls "$5" >/dev/null 2>&1 && echo "FOUND icon $5" || die "Icon $5 NOT found"

# Store arguments under better names
source=$1
bgpic=$2
bgpicname=$(basename ${bgpic})
title=$3
size=$4
icon=$5
iconname=$(basename "${icon}")

# Create a disk image and attach (mount) it
hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k pack.temp.dmg
device=$(hdiutil attach -readwrite -noverify -noautoopen "pack.temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5

echo "Created and attached device: ${device}"

# Copy the background picture to the attached disk image
mkdir /Volumes/"${title}"/.background/
cp ${bgpic} /Volumes/"${title}"/.background/${bgpicname}

# Generate some applescript to setup the visuals of the disk image 
echo '
   tell application "Finder"
     tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {100, 100, 800, 600}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 256
           set background picture of theViewOptions to file ".background:'${bgpicname}'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${title}'" of container window to {148, 204}
           set position of item "Applications" of container window to {521, 204}
		   close
		   open
           update without registering applications
           delay 5
     end tell
   end tell
' | osascript

# Set the disk image to readonly and compress it
chmod -Rf go-w /Volumes/"${title}"
sync
sync
hdiutil detach ${device}
hdiutil convert "pack.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${title}-disk-image"
rm -f pack.temp.dmg 

# Copy resulting *.dmg file to ./OUT (create folder if not already existing)
mkdir -p -m 777 ./OUT || die "Could not create OUT directory"
mv -f ./"${title}-disk-image.dmg" ./OUT/"${title}-disk-image.dmg"

#EOF