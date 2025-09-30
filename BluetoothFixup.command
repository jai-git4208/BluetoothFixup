#!/bin/bash
set -e

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
NC="\033[0m" # No Color

EFI_DIR="/Volumes/EFI/EFI/OC"
PLIST="$EFI_DIR/config.plist"
KEXTS_TO_INSTALL=()
NVRAM_NEEDED=false

# Detect macOS version
detect_macos_version() {
    local version=$(sw_vers -productVersion)
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    
    echo -e "${BLUE}Detected macOS version: ${GREEN}$version${NC}"
    
    if [ "$major" -ge 12 ]; then
        echo -e "${YELLOW}macOS 12+ detected - BlueToolFixup required${NC}"
        MACOS_VERSION="12+"
        NVRAM_NEEDED=true
    elif [ "$major" -eq 10 ] && [ "$minor" -ge 15 ]; then
        echo -e "${YELLOW}macOS 10.15+ detected - BrcmPatchRAM3 + BrcmBluetoothInjector required${NC}"
        MACOS_VERSION="10.15+"
    elif [ "$major" -eq 10 ] && [ "$minor" -ge 11 ]; then
        echo -e "${YELLOW}macOS 10.11-10.14 detected - BrcmPatchRAM2 required${NC}"
        MACOS_VERSION="10.11-10.14"
    else
        echo -e "${YELLOW}macOS 10.10 or earlier detected - BrcmPatchRAM required${NC}"
        MACOS_VERSION="10.10-"
    fi
}

# Detect Bluetooth device
detect_bluetooth_device() {
    echo -e "${BLUE}Detecting Bluetooth devices...${NC}"
    
    # Get USB Bluetooth devices
    local devices=$(system_profiler SPBluetoothDataType SPUSBDataType 2>/dev/null | grep -A 5 "Bluetooth")
    
    if [ -z "$devices" ]; then
        echo -e "${YELLOW}No Bluetooth device information found via system_profiler${NC}"
        echo -e "${CYAN}Please select your Bluetooth device type:${NC}"
        echo -e "${YELLOW}1.${NC} Intel Bluetooth"
        echo -e "${YELLOW}2.${NC} Broadcom Bluetooth (PatchRAM device)"
        echo -e "${YELLOW}3.${NC} Broadcom Bluetooth (Non-PatchRAM device)"
        echo -e "${YELLOW}4.${NC} Unknown/Skip detection"
        read -p "Enter choice (1-4): " device_choice
        
        case "$device_choice" in
            1) DEVICE_TYPE="intel" ;;
            2) DEVICE_TYPE="broadcom_patchram" ;;
            3) DEVICE_TYPE="broadcom_nonpatchram" ;;
            4) DEVICE_TYPE="unknown" ;;
            *) echo -e "${RED}Invalid choice${NC}"; return 1 ;;
        esac
    else
        # Try to detect automatically
        if echo "$devices" | grep -qi "intel"; then
            DEVICE_TYPE="intel"
            echo -e "${GREEN}Intel Bluetooth device detected${NC}"
        elif echo "$devices" | grep -qi "broadcom\|bcm"; then
            echo -e "${YELLOW}Broadcom device detected. Is this a PatchRAM device? (y/n)${NC}"
            read -p "Answer: " is_patchram
            if [[ "$is_patchram" =~ ^[Yy] ]]; then
                DEVICE_TYPE="broadcom_patchram"
            else
                DEVICE_TYPE="broadcom_nonpatchram"
            fi
        else
            DEVICE_TYPE="unknown"
            echo -e "${YELLOW}Could not determine device type automatically${NC}"
        fi
    fi
    
    echo -e "${GREEN}Device type set to: $DEVICE_TYPE${NC}"
}

# Determine required kexts
determine_required_kexts() {
    echo -e "${BLUE}Determining required kexts...${NC}"
    KEXTS_TO_INSTALL=()
    
    # Intel Bluetooth
    if [ "$DEVICE_TYPE" == "intel" ]; then
        KEXTS_TO_INSTALL+=("IntelBluetoothFirmware.kext")
        
        if [ "$MACOS_VERSION" == "12+" ]; then
            KEXTS_TO_INSTALL+=("BlueToolFixup.kext")
        elif [ "$MACOS_VERSION" == "10.15+" ]; then
            KEXTS_TO_INSTALL+=("IntelBTPatcher.kext")
        fi
    fi
    
    # Broadcom PatchRAM
    if [ "$DEVICE_TYPE" == "broadcom_patchram" ]; then
        # Firmware store (prefer Data for bootloader injection)
        KEXTS_TO_INSTALL+=("BrcmFirmwareData.kext")
        
        if [ "$MACOS_VERSION" == "12+" ]; then
            KEXTS_TO_INSTALL+=("BrcmPatchRAM3.kext")
            KEXTS_TO_INSTALL+=("BlueToolFixup.kext")
        elif [ "$MACOS_VERSION" == "10.15+" ]; then
            KEXTS_TO_INSTALL+=("BrcmPatchRAM3.kext")
            KEXTS_TO_INSTALL+=("BrcmBluetoothInjector.kext")
        elif [ "$MACOS_VERSION" == "10.11-10.14" ]; then
            KEXTS_TO_INSTALL+=("BrcmPatchRAM2.kext")
        else
            KEXTS_TO_INSTALL+=("BrcmPatchRAM.kext")
        fi
    fi
    
    # Broadcom Non-PatchRAM
    if [ "$DEVICE_TYPE" == "broadcom_nonpatchram" ]; then
        if [ "$MACOS_VERSION" == "10.11-10.14" ] || [ "$MACOS_VERSION" == "10.15+" ] || [ "$MACOS_VERSION" == "12+" ]; then
            KEXTS_TO_INSTALL+=("BrcmNonPatchRAM2.kext")
            # Still needs base PatchRAM kext
            if [ "$MACOS_VERSION" == "12+" ]; then
                KEXTS_TO_INSTALL+=("BrcmPatchRAM3.kext")
            elif [ "$MACOS_VERSION" == "10.15+" ]; then
                KEXTS_TO_INSTALL+=("BrcmPatchRAM3.kext")
            elif [ "$MACOS_VERSION" == "10.11-10.14" ]; then
                KEXTS_TO_INSTALL+=("BrcmPatchRAM2.kext")
            fi
        else
            KEXTS_TO_INSTALL+=("BrcmNonPatchRAM.kext")
            KEXTS_TO_INSTALL+=("BrcmPatchRAM.kext")
        fi
    fi
    
    if [ ${#KEXTS_TO_INSTALL[@]} -eq 0 ]; then
        echo -e "${YELLOW}No kexts determined. Manual selection may be required.${NC}"
    else
        echo -e "${GREEN}Required kexts:${NC}"
        for kext in "${KEXTS_TO_INSTALL[@]}"; do
            echo -e "  ${CYAN}→${NC} $kext"
        done
    fi
}

# Mount EFI
mount_efi() {
    echo -e "${BLUE}Mounting EFI...${NC}"
    if [ -d "/Volumes/EFI" ]; then
        echo -e "${YELLOW}EFI already mounted${NC}"
        return 0
    fi
    
    if [ -f "MountEFI/MountEFI.command" ]; then
        chmod +x "MountEFI/MountEFI.command"
        MountEFI/MountEFI.command
    else
        # Alternative mounting method
        local efi_partition=$(diskutil list | grep "EFI" | head -n 1 | awk '{print $NF}')
        if [ -n "$efi_partition" ]; then
            sudo diskutil mount "$efi_partition"
        else
            echo -e "${RED}Could not find EFI partition${NC}"
            return 1
        fi
    fi
    
    if [ -d "/Volumes/EFI" ]; then
        echo -e "${GREEN}EFI Mounted successfully.${NC}"
    else
        echo -e "${RED}Failed to mount EFI${NC}"
        return 1
    fi
}

# Copy kexts
copy_kexts() {
    if [ ${#KEXTS_TO_INSTALL[@]} -eq 0 ]; then
        echo -e "${RED}No kexts selected. Please run detection first (option 1).${NC}"
        return 1
    fi
    
    if [ ! -d "$EFI_DIR/Kexts" ]; then
        echo -e "${RED}EFI directory not found. Please mount EFI first.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Copying kexts...${NC}"
    
    for kext in "${KEXTS_TO_INSTALL[@]}"; do
        if [ -d "Kexts/$kext" ]; then
            echo -e "${CYAN}Copying $kext...${NC}"
            cp -R "Kexts/$kext" "$EFI_DIR/Kexts/"
            echo -e "${GREEN}✓ $kext copied.${NC}"
        else
            echo -e "${YELLOW}⚠ $kext not found in Kexts/ directory${NC}"
        fi
    done
    
    echo -e "${GREEN}Kext copying complete.${NC}"
}

# Update config.plist
update_plist() {
    if [ ${#KEXTS_TO_INSTALL[@]} -eq 0 ]; then
        echo -e "${RED}No kexts selected. Please run detection first (option 1).${NC}"
        return 1
    fi
    
    if [ ! -f "$PLIST" ]; then
        echo -e "${RED}config.plist not found at $PLIST${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating config.plist...${NC}"
    
    # Backup config.plist
    cp "$PLIST" "${PLIST}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}Backup created at: ${PLIST}.backup.$(date +%Y%m%d_%H%M%S)${NC}"
    
    # Check if Kernel:Add exists, if not create it
    /usr/libexec/PlistBuddy -c "Print :Kernel:Add" "$PLIST" &>/dev/null || {
        echo -e "${YELLOW}Creating Kernel:Add array...${NC}"
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add array" "$PLIST"
    }
    
    # Get current number of kext entries
    local current_kexts=$(/usr/libexec/PlistBuddy -c "Print :Kernel:Add" "$PLIST" 2>/dev/null | grep -c "Dict {" || echo "0")
    echo -e "${BLUE}Current kexts in config: $current_kexts${NC}"
    
    # Add each kext
    for kext in "${KEXTS_TO_INSTALL[@]}"; do
        echo -e "${CYAN}Adding $kext to config.plist...${NC}"
        
        # Add new dictionary entry to array
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add: dict" "$PLIST"
        
        # Get the index of the newly added entry (last item)
        local index=$(/usr/libexec/PlistBuddy -c "Print :Kernel:Add" "$PLIST" 2>/dev/null | grep -c "Dict {")
        ((index--))
        
        # Populate the dictionary
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:Arch string Any" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:BundlePath string $kext" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:Comment string Added by Bluetooth setup script" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:Enabled bool true" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:ExecutablePath string Contents/MacOS/${kext%.kext}" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:MaxKernel string" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:MinKernel string" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :Kernel:Add:$index:PlistPath string Contents/Info.plist" "$PLIST" 2>/dev/null || true
        
        echo -e "${GREEN}✓ $kext added successfully${NC}"
    done
    
    # Add NVRAM variables if needed
    if [ "$NVRAM_NEEDED" == true ]; then
        echo -e "${BLUE}Adding NVRAM variables for macOS 12+...${NC}"
        /usr/libexec/PlistBuddy -c "Add :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:bluetoothExternalDongleFailed data 00" "$PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Set :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:bluetoothExternalDongleFailed 00" "$PLIST"
        
        /usr/libexec/PlistBuddy -c "Add :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:bluetoothInternalControllerInfo data 0000000000000000000000000000" "$PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Set :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:bluetoothInternalControllerInfo 0000000000000000000000000000" "$PLIST"
        
        echo -e "${GREEN}NVRAM variables added${NC}"
    fi
    
    echo -e "${GREEN}config.plist updated successfully.${NC}"
}

# Show configuration summary
show_summary() {
    echo -e "\n${CYAN}═══════════════════ Configuration Summary ═══════════════════${NC}"
    echo -e "${BLUE}macOS Version:${NC} $MACOS_VERSION"
    echo -e "${BLUE}Device Type:${NC} $DEVICE_TYPE"
    echo -e "${BLUE}Kexts to Install:${NC}"
    
    if [ ${#KEXTS_TO_INSTALL[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}None selected${NC}"
    else
        for kext in "${KEXTS_TO_INSTALL[@]}"; do
            echo -e "  ${GREEN}→${NC} $kext"
        done
    fi
    
    if [ "$NVRAM_NEEDED" == true ]; then
        echo -e "${YELLOW}⚠ NVRAM variables will be configured${NC}"
    fi
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
}

# Reboot system
reboot_system() {
    echo -e "${RED}⚠ This will reboot your system!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo -e "${RED}Rebooting in 3 seconds...${NC}"
        sleep 3
        sudo reboot
    else
        echo -e "${YELLOW}Reboot cancelled${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "\n${CYAN}═══════════════════ EFI Bluetooth Update Menu ═══════════════════${NC}"
    echo -e "${YELLOW}1.${NC} Auto-detect system and determine required kexts"
    echo -e "${YELLOW}2.${NC} Show configuration summary"
    echo -e "${YELLOW}3.${NC} Mount EFI"
    echo -e "${YELLOW}4.${NC} Copy kexts to EFI"
    echo -e "${YELLOW}5.${NC} Update config.plist"
    echo -e "${YELLOW}6.${NC} Complete installation (steps 3-5)"
    echo -e "${YELLOW}7.${NC} Reboot system"
    echo -e "${YELLOW}8.${NC} Exit"
    echo -e "${CYAN}═════════════════════════════════════════════════════════════════${NC}"
}

# Main loop
main() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     macOS Bluetooth Kext Installation Manager            ║"
    echo "║     Based on BrcmPatchRAM & IntelBluetooth              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    while true; do
        show_menu
        read -p "Enter your choice (1-8): " choice
        
        case "$choice" in
            1)
                detect_macos_version
                detect_bluetooth_device
                determine_required_kexts
                ;;
            2)
                show_summary
                ;;
            3)
                mount_efi
                ;;
            4)
                copy_kexts
                ;;
            5)
                update_plist
                ;;
            6)
                echo -e "${BLUE}Starting complete installation...${NC}"
                mount_efi && copy_kexts && update_plist
                echo -e "${GREEN}Installation complete!${NC}"
                ;;
            7)
                reboot_system
                ;;
            8)
                echo -e "${GREEN}Exiting...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please choose 1-8.${NC}"
                ;;
        esac
        
        if [ "$choice" != "8" ]; then
            read -p "Press Enter to continue..."
        fi
    done
}

# Run main
main