#!/bin/bash
set -e

echo "➡️  Mounting EFI..."

chmod +x "MountEFI/MountEFI.command"
MountEFI/MountEFI.command

EFI_DIR="/Volumes/EFI/EFI/OC"

echo "➡️  Copying kexts..."
cp -R "Kexts/BlueToolFixup.kext" "$EFI_DIR/Kexts/"
cp -R "Kexts/IntelBluetoothFirmware.kext" "$EFI_DIR/Kexts/"

PLIST="$EFI_DIR/config.plist"

echo "➡️  Updating config.plist..."
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:0 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:0:BundlePath string BlueToolFixup.kext" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:0:Enabled bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:0:ExecutablePath string Contents/MacOS/BlueToolFixup" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:0:PlistPath string Contents/Info.plist" "$PLIST"

/usr/libexec/PlistBuddy -c "Add :Kernel:Add:1 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:1:BundlePath string IntelBluetoothFirmware.kext" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:1:Enabled bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:1:ExecutablePath string Contents/MacOS/IntelBluetoothFirmware" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Kernel:Add:1:PlistPath string Contents/Info.plist" "$PLIST"

echo "✅  Done. EFI updated."
echo "💡  Made with ♥️ by JAIMIN"
