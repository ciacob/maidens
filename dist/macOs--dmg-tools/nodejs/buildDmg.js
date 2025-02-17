const fs = require("fs");
const { execSync } = require("child_process");
const path = require("path");
const crypto = require("crypto");

function generateUniqueCombination() {
  return crypto.randomBytes(3).toString('hex').substring(0, 5);
}

// Function to clear directory contents
function clearDirectory(directory) {
  if (fs.existsSync(directory)) {
    fs.readdirSync(directory).forEach((file) => {
      const filePath = path.join(directory, file);
      if (fs.lstatSync(filePath).isDirectory()) {
        fs.rmSync(filePath, { recursive: true, force: true });
      } else {
        fs.unlinkSync(filePath);
      }
    });
  }
}

// 🔧 --- CONFIGURATION (EDIT THESE CONSTANTS) ---

// Name of the application
const APP_NAME = "MAIDENS";

// Path to the patched/notarized AIR application home directory
const PATCHED_APP_DIR = `/Users/ciacob/_DEV_/github/actionscript/maidens/dist-interim`;

// Path to the patched/notarized AIR application (with changed image, added file association, etc.)
const PATCHED_APP_PATH = `${PATCHED_APP_DIR}/${APP_NAME}.app`;

// Name of the output DMG
const DMG_NAME = "maidens-1.5.7-installation.dmg";

// Volume name when mounted
const DMG_TITLE = "Installation Disk for MAIDENS 1.5.7"; 

// Background image
const DMG_BACKGROUND_IMG = "/Users/ciacob/_DEV_/github/actionscript/maidens/dist/macOs--dmg-tools/mac-dmg-image.psd";

// Your Apple Developer certificate
const CERTIFICATE = "ciacob";

// Directory to export the final DMG into
const DMG_OUT_DIR = '/Users/ciacob/_DEV_/github/actionscript/maidens/dist-out';

// --- END OF CONFIGURATION ---

// Derived paths
const TEMP_DMG = `${DMG_OUT_DIR}/temp.${generateUniqueCombination()}.dmg`;
const FINAL_DMG = `${DMG_OUT_DIR}/${DMG_NAME}`;



// Clear the contents of DMG_OUT_DIR
console.log("🗑 Clearing contents of the final export location...");
clearDirectory(DMG_OUT_DIR);

// Verify the directory is empty
if (fs.readdirSync(DMG_OUT_DIR).length === 0) {
  console.log("✅ Directory cleared successfully.");
} else {
  console.error(
    "❌ Could not clear the directory. Please make sure it is empty and try again."
  );
  process.exit(1);
}

// 🛠 STEP 1: Calculate the `.app` size
console.log("📏 Calculating application size...");
const appSizeKb = parseInt(
  execSync(`du -sk "${PATCHED_APP_PATH}" | cut -f1`).toString().trim(),
  10
);
const dmgSizeKb = appSizeKb * 2; // Give it enough space
console.log(`📦 App size: ${appSizeKb} KB, Allocating: ${dmgSizeKb} KB for DMG`);

// 🛠 STEP 2: Create the `.dmg` with background and layout
console.log("📀 Creating the DMG...");

execSync(
  `hdiutil create -volname "${DMG_TITLE}" -srcfolder "${PATCHED_APP_PATH}" -fs HFS+ ` +
    `-format UDRW -size ${dmgSizeKb}k "${TEMP_DMG}"`,
  { stdio: "inherit" }
);

// Attach DMG
console.log("📌 Mounting DMG...");
const device = execSync(`hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}" | grep '^/dev/' | head -n 1 | awk '{print $1}'`)
  .toString().trim();
console.log(`📂 Mounted at: ${device}`);

// Copy background image
console.log("🖼️ Adding background image...");
execSync(`mkdir /Volumes/"${DMG_TITLE}"/.background/`);
execSync(`cp "${DMG_BACKGROUND_IMG}" /Volumes/"${DMG_TITLE}"/.background/`);

// Configure Finder layout
console.log("📝 Configuring Finder layout...");
const appleScript = `
tell application "Finder"
    tell disk "${DMG_TITLE}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 810, 620}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 256
        set background picture of theViewOptions to file ".background:${path.basename(DMG_BACKGROUND_IMG)}"
        make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
        set position of item ".background" of container window to {830, 204}
        set position of item ".fseventsd" of container window to {1086, 204}
        set position of item "${APP_NAME}" of container window to {148, 204}
        set position of item "Applications" of container window to {521, 204}
        close
        open
        update without registering applications
        delay 5
    end tell
end tell
`;
execSync(`osascript -e '${appleScript}'`);

// Unmount and finalize DMG
console.log("📤 Finalizing DMG...");
execSync(`chmod -Rf go-w /Volumes/"${DMG_TITLE}"`);
execSync("sync");
execSync(`hdiutil detach "${device}"`);
execSync(`hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"`);
fs.unlinkSync(TEMP_DMG); // Remove temp file

// 🛠 STEP 4: Sign the `.dmg`
console.log("🔏 Signing the DMG...");
execSync(`codesign --sign "${CERTIFICATE}" --force --verbose "${FINAL_DMG}"`, { stdio: "inherit" });

// 🛠 STEP 5: Notarize the `.dmg`
// console.log("📤 Submitting DMG for notarization...");
// execSync(
//   `xcrun notarytool submit "${FINAL_DMG}" --apple-id "${APPLE_ID}" --password "${APPLE_APP_PASSWORD}" --team-id "${APPLE_TEAM_ID}"`,
//   { stdio: "inherit" }
// );

console.log ("\nDMG created and signed successfully!");
// console.log("\n✅ DMG creation, signing, and notarization submitted successfully!");
// console.log(`\n🚀 Once notarization is approved, run this command to staple it:\n`);
// console.log(`xcrun stapler staple "${FINAL_DMG}"`);
