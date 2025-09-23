#!/bin/bash
set -e

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

EFI_DIR="/Volumes/EFI/EFI/OC"
PLIST="$EFI_DIR/config.plist"

# Functions
mount_efi() {
    echo -e "${BLUE}Mounting EFI...${NC}"
    chmod +x "MountEFI/MountEFI.command"
    MountEFI/MountEFI.command
    echo -e "${GREEN}EFI Mounted successfully.${NC}"
}

copy_kexts() {
    echo -e "${BLUE}Copying kexts...${NC}"
    cp -R "Kexts/BlueToolFixup.kext" "$EFI_DIR/Kexts/"
    echo -e "${GREEN}BlueToolFixup.kext copied.${NC}"
    cp -R "Kexts/IntelBluetoothFirmware.kext" "$EFI_DIR/Kexts/"
    echo -e "${GREEN}IntelBluetoothFirmware.kext copied.${NC}"
}

update_plist() {
    echo -e "${BLUE}Updating config.plist...${NC}"
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
    
    echo -e "${GREEN}config.plist updated successfully.${NC}"
}

reboot_system() {
    echo -e "${RED}Rebooting your PC...${NC}"
    sudo reboot
}

# Main menu loop
while true; do
    echo -e "\n${CYAN}================ EFI Update Menu ================"
    echo -e "${YELLOW}1.${NC} Mount EFI"
    echo -e "${YELLOW}2.${NC} Copy Kexts"
    echo -e "${YELLOW}3.${NC} Update config.plist"
    echo -e "${YELLOW}4.${NC} Reboot"
    echo -e "${YELLOW}5.${NC} Exit"
    echo -e "${CYAN}==============================================${NC}"
    read -p "Enter your choice (1-5): " choice

    case "$choice" in
        1) mount_efi ;;
        2) copy_kexts ;;
        3) update_plist ;;
        4) reboot_system ;;
        5) echo -e "${GREEN}Exiting...${NC}"; break ;;
        *) echo -e "${RED}Invalid choice. Please choose 1-5.${NC}" ;;
    esac
done
