const fs = require("fs");
const { execSync } = require("child_process");
const plist = require("plist");
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

// Path to the AIR application, as packed by adt
const ORIGINAL_APP_PATH = `/Users/ciacob/_DEV_/github/actionscript/maidens/dist-src/${APP_NAME}-tmp.app`;

// Path to the patched AIR application home directory
const PATCHED_APP_DIR = `/Users/ciacob/_DEV_/github/actionscript/maidens/dist-interim`;

// Path to the patched AIR application (with changed image, added file association, etc.)
const PATCHED_APP_PATH = `${PATCHED_APP_DIR}/${APP_NAME}`;

// macOS bundle ID
const BUNDLE_IDENTIFIER = `ro.ciacob.apps.desktop.maidens.${generateUniqueCombination()}`;

// Where to copy app icon from
const SRC_ICON_PATH =
  "/Users/ciacob/_DEV_/github/actionscript/maidens/bin/assets/images/maidens-application-icon.icns";

// Path to the custom file icon
const SRC_FILE_ICON_PATH =
  "/Users/ciacob/_DEV_/github/actionscript/maidens/bin/assets/images/maidens-project-file-icon.icns";

// Extension to be used for the custom file association
const FILE_EXTENSION = "maid";

// Keychain name of certificate to be used for signing
const CERTIFICATE = "ciacob-self-signed";

// --- END OF CONFIGURATION ---

// Derived paths
const PLIST_PATH = `${PATCHED_APP_PATH}/Contents/Info.plist`;
const MACOS_EXECUTABLE = `${PATCHED_APP_PATH}/Contents/MacOS/${APP_NAME}`;
const RESOURCES_PATH = `${PATCHED_APP_PATH}/Contents/Resources`;
const BUNDLED_ICON_PATH = `${RESOURCES_PATH}/${path.basename(SRC_ICON_PATH)}`;
const BUNDLED_FILE_ICON_PATH = `${RESOURCES_PATH}/${path.basename(
  SRC_FILE_ICON_PATH
)}`;

// Clear the contents of PATCHED_APP_PATH
console.log("🗑 Clearing contents of the interim location...");
clearDirectory(PATCHED_APP_DIR);

// Verify the directory is empty
if (fs.readdirSync(PATCHED_APP_DIR).length === 0) {
  console.log("✅ Directory cleared successfully.");
} else {
  console.error(
    "❌ Could not clear the directory. Please make sure it is empty and try again."
  );
  process.exit(1);
}

// 🛠 STEP 1: Copy the original app to the interim location
console.log(
  "🛠 Copying the original app to the interim location for patching..."
);
execSync(`ditto "${ORIGINAL_APP_PATH}" "${PATCHED_APP_PATH}"`);

// 🛠 STEP 2: Modify the `.app` bundle
console.log("🛠 Patching the application bundle...");

// Ensure the resources folder exists within the app bundle
if (!fs.existsSync(RESOURCES_PATH)) {
  fs.mkdirSync(RESOURCES_PATH, { recursive: true });
}

// Copy the custom icon
console.log("🎨 Setting custom app icon...");
fs.copyFileSync(SRC_ICON_PATH, BUNDLED_ICON_PATH);

// Copy the custom file icon
console.log("🎨 Setting custom file icon...");
fs.copyFileSync(SRC_FILE_ICON_PATH, BUNDLED_FILE_ICON_PATH);

// Modify `Info.plist`
console.log("📝 Updating Info.plist...");
let plistData = plist.parse(fs.readFileSync(PLIST_PATH, "utf8"));

// Set bundle ID
plistData["CFBundleIdentifier"] = BUNDLE_IDENTIFIER;

// Set app icon reference
plistData["CFBundleIconFile"] = path.basename(SRC_ICON_PATH, ".icns");

// Register file extension with custom icon
plistData["CFBundleDocumentTypes"] = [
  {
    CFBundleTypeExtensions: [FILE_EXTENSION],
    CFBundleTypeName: "Custom File",
    CFBundleTypeRole: "Editor",
    CFBundleTypeIconFile: path.basename(SRC_FILE_ICON_PATH, ".icns"),
  },
];

// Save updated Info.plist
fs.writeFileSync(PLIST_PATH, plist.build(plistData), "utf8");

// Ensure the main binary is executable
console.log("🔧 Setting executable permissions...");
execSync(`chmod +x ${MACOS_EXECUTABLE}`);

// 🛠 STEP 3: Sign the app with `codesign`
console.log("🔏 Signing the application...");
execSync(
  `codesign --deep --force --verbose --sign "${CERTIFICATE}" "${PATCHED_APP_PATH}"`,
  { stdio: "inherit" }
);

// 🛠 STEP 4: Rename the patched app, adding the `.app` extension. We kept it extension-less to prevent the icons service
// from recognizing it as an application and caching the icon.
fs.renameSync(PATCHED_APP_PATH, `${PATCHED_APP_PATH}.app`);

// 🛠 STEP 5: Notarize the app with Apple (TBD)
// console.log("📤 Submitting app for notarization...");
// const ZIP_NAME = `${APP_NAME}.zip`;
// execSync(`ditto -c -k --keepParent "${OUTPUT_APP}" "${ZIP_NAME}"`);
// execSync(
//   `xcrun notarytool submit "${ZIP_NAME}" --apple-id "${APPLE_ID}" --password "${APPLE_APP_PASSWORD}" --team-id "${APPLE_TEAM_ID}"`,
//   { stdio: "inherit" }
// );

console.log("\n✅ All steps completed!");
// console.log ("Please run the following command manually to staple the notarization once it's ready:");
// console.log(`xcrun stapler staple "${PATCHED_APP_PATH}"`);
