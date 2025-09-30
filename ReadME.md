# macOS Bluetooth Kext Installation Manager

An intelligent, automated script for installing and configuring Bluetooth kexts (BrcmPatchRAM, IntelBluetooth, BlueToolFixup) on Hackintosh systems running OpenCore.

## 🌟 Features

- **Automatic Detection**: Detects macOS version and Bluetooth device type
- **Smart Configuration**: Determines required kexts based on your system
- **Version-Aware**: Supports macOS 10.10 through macOS 15+
- **Safe Operations**: Automatic config.plist backup before modifications
- **NVRAM Setup**: Configures required NVRAM variables for macOS 12+
- **Interactive Menu**: User-friendly interface with color-coded output
- **One-Click Installation**: Complete setup with a single option

---

## 📋 Prerequisites

- **OpenCore Bootloader** installed
- **EFI partition** accessible
- **macOS** 10.10 or later
- **Sudo/Admin privileges** for EFI mounting
- **Required kext files** in a `Kexts/` directory

---

## 📁 Directory Structure

```
.
├── BluetoothFixup.command                    # Main script
├── MountEFI/
│   └── MountEFI.command         # EFI mounting utility (optional)
└── Kexts/                       # kext files
    ├── BlueToolFixup.kext
    ├── BrcmPatchRAM.kext
    ├── BrcmPatchRAM2.kext
    ├── BrcmPatchRAM3.kext
    ├── BrcmBluetoothInjector.kext
    ├── BrcmFirmwareData.kext
    ├── BrcmFirmwareRepo.kext
    ├── BrcmNonPatchRAM.kext
    ├── BrcmNonPatchRAM2.kext
    ├── IntelBluetoothFirmware.kext
    └── IntelBTPatcher.kext
```

---

## 🚀 Quick Start

### 1. Download and Prepare

```bash
# Clone or download the script
chmod +x BluetoothFixup.command

# Ensure kext files are in Kexts/ directory
ls Kexts/
```

### 2. Run the Script

```bash
./BluetoothFixup.command
```

### 3. Follow the Menu

```
═══════════════════ EFI Bluetooth Update Menu ═══════════════════
1. Auto-detect system and determine required kexts
2. Show configuration summary
3. Mount EFI
4. Copy kexts to EFI
5. Update config.plist
6. Complete installation (steps 3-5)
7. Reboot system
8. Exit
═════════════════════════════════════════════════════════════════
```

**Recommended workflow:**
1. Select **Option 1** to detect your system
2. Select **Option 2** to review what will be installed
3. Select **Option 6** for one-click complete installation
4. Select **Option 7** to reboot

---

## 🔍 What the Script Does

### Option 1: Auto-Detection

**Detects macOS Version:**
- macOS 12+ (Monterey and newer)
- macOS 10.15+ (Catalina, Big Sur)
- macOS 10.11-10.14 (El Capitan through Mojave)
- macOS 10.10 and earlier

**Identifies Bluetooth Device:**
- Intel Bluetooth chipsets
- Broadcom PatchRAM devices (RAMUSB)
- Broadcom Non-PatchRAM devices (built-in firmware)

**Determines Required Kexts:**

Based on your configuration, the script selects the appropriate combination:

#### For Intel Bluetooth:
| macOS Version | Required Kexts |
|---------------|----------------|
| macOS 12+ | IntelBluetoothFirmware + BlueToolFixup |
| macOS 10.15+ | IntelBluetoothFirmware + IntelBTPatcher |
| macOS 10.11-10.14 | IntelBluetoothFirmware |

#### For Broadcom PatchRAM:
| macOS Version | Required Kexts |
|---------------|----------------|
| macOS 12+ | BrcmPatchRAM3 + BrcmFirmwareData + BlueToolFixup |
| macOS 10.15+ | BrcmPatchRAM3 + BrcmFirmwareData + BrcmBluetoothInjector |
| macOS 10.11-10.14 | BrcmPatchRAM2 + BrcmFirmwareData |
| macOS ≤10.10 | BrcmPatchRAM + BrcmFirmwareData |

#### For Broadcom Non-PatchRAM:
| macOS Version | Required Kexts |
|---------------|----------------|
| macOS 12+ | BrcmPatchRAM3 + BrcmNonPatchRAM2 |
| macOS 10.15+ | BrcmPatchRAM3 + BrcmNonPatchRAM2 |
| macOS 10.11-10.14 | BrcmPatchRAM2 + BrcmNonPatchRAM2 |
| macOS ≤10.10 | BrcmPatchRAM + BrcmNonPatchRAM |

### Option 3: Mount EFI

- Attempts to mount EFI partition using MountEFI utility
- Falls back to diskutil if utility not available
- Verifies successful mount at `/Volumes/EFI`

### Option 4: Copy Kexts

- Copies selected kexts to `/Volumes/EFI/EFI/OC/Kexts/`
- Verifies each kext exists before copying
- Provides feedback for each operation

### Option 5: Update config.plist

**Creates automatic backup:**
- Location: `/Volumes/EFI/EFI/OC/config.plist.backup.YYYYMMDD_HHMMSS`
- Timestamped to prevent overwriting previous backups

**Adds kexts to Kernel → Add:**
- BundlePath
- Enabled (set to true)
- ExecutablePath
- PlistPath
- Arch (set to "Any")
- MinKernel and MaxKernel (empty for compatibility)
- Comment (marks as added by script)

**Configures NVRAM (macOS 12+ with Intel Bluetooth):**
```
7C436110-AB2A-4BBB-A880-FE41995C9F82:
  - bluetoothExternalDongleFailed: 00
  - bluetoothInternalControllerInfo: 0000000000000000000000000000
```

---

## 🛠️ Supported Devices

### Intel Bluetooth Devices
All Intel Bluetooth devices are supported through IntelBluetoothFirmware.

### Broadcom PatchRAM Devices (Partial List)
- Dell DW1560, DW1830, DW1550 (4352/20702)
- HP modules (various models)
- Lenovo modules (various models)
- Asus modules (various models)
- Azurewave modules (various models)
- Toshiba modules (various models)
- Generic BCM20702, BCM4352, BCM43142 chipsets

**Check full list:** See BrcmBluetoothInjector section in included README_BrcmPatchRAM.md

### Broadcom Non-PatchRAM Devices
- HP ProBook built-in Bluetooth
- Apple original Bluetooth modules
- Azurewave BCM943225

---

## 📖 Understanding Device Types

### 🔵 PatchRAM Devices (RAMUSB)

**What they are:**
- RAM-based firmware that resets on shutdown/sleep
- Require firmware upload on every boot
- Firmware version shows as "4096" without kexts

**How to identify:**
1. Go to: **About This Mac → System Report → Bluetooth**
2. Check **Firmware Version**
3. If it shows **"4096"** or **"v4096"** → PatchRAM device

**What the script does:**
- Uploads firmware on every startup
- Version changes from 4096 to actual version (e.g., v5708)
- Enables full Bluetooth functionality

### 🟢 Non-PatchRAM Devices

**What they are:**
- Built-in permanent firmware in ROM/Flash
- Don't lose firmware on shutdown
- Work immediately when plugged in

**How to identify:**
1. Firmware version shows something other than 4096
2. Works without firmware upload

**What the script does:**
- Optimizes sleep/wake behavior
- Ensures proper device recognition

---

## ⚙️ Configuration Options

### EFI Directory Path
Default: `/Volumes/EFI/EFI/OC`

To change, edit the script:
```bash
EFI_DIR="/Volumes/EFI/EFI/OC"  # Modify this line
```

### Kext Source Directory
Default: `./Kexts/`

Ensure all required kexts are in this directory before running.

---

## 🐛 Troubleshooting

### Bluetooth Not Working After Installation

**1. Check Firmware Version:**
```bash
system_profiler SPBluetoothDataType | grep "Firmware Version"
```
- If still shows "4096" → Firmware not uploaded correctly
- Should show version like "v5708" for working PatchRAM

**2. Check System Logs:**
```bash
# For macOS 10.12+
log show --last boot | grep -i brcm

# For older macOS
cat /var/log/system.log | grep -i brcm
```

**3. Verify Kexts Loaded:**
```bash
kextstat | grep -i bluetooth
```

Should show:
- `com.apple.iokit.BroadcomBluetoothHostControllerUSBTransport`
- Your installed BrcmPatchRAM kexts

**4. Check config.plist:**
- Verify kexts are enabled (Enabled = true)
- Check kext order (firmware kexts should load before PatchRAM)
- Ensure no conflicting kexts

### Common Issues

**"Unrecognized Type" Error:**
- Fixed in current version
- Script now properly handles plist array structure

**EFI Won't Mount:**
- Try manual mount: `sudo diskutil mount disk0s1` (adjust disk number)
- Check if EFI partition exists: `diskutil list`

**Kexts Not Copying:**
- Verify kexts exist in `Kexts/` directory
- Check permissions: `ls -la Kexts/`
- Ensure EFI is mounted and writable

**Config.plist Corruption:**
- Restore from backup: 
  ```bash
  cp /Volumes/EFI/EFI/OC/config.plist.backup.* /Volumes/EFI/EFI/OC/config.plist
  ```
- Always keep backup before modifications

### macOS 12+ Specific Issues

**Bluetooth appears but doesn't work:**
- Verify NVRAM variables are set:
  ```bash
  nvram -p | grep bluetooth
  ```
- Should show:
  - `bluetoothExternalDongleFailed`
  - `bluetoothInternalControllerInfo`

**Alternative NVRAM setup:**
If script fails to set NVRAM, add manually to config.plist:
```xml
<key>NVRAM</key>
<dict>
    <key>Add</key>
    <dict>
        <key>7C436110-AB2A-4BBB-A880-FE41995C9F82</key>
        <dict>
            <key>bluetoothExternalDongleFailed</key>
            <data>AA==</data>
            <key>bluetoothInternalControllerInfo</key>
            <data>AAAAAAAAAAAAAAAAAAAAAA==</data>
        </dict>
    </dict>
</dict>
```

---

## 📦 Backup and Restore

### Automatic Backups

The script creates automatic backups before any config.plist modifications:
- **Location:** `/Volumes/EFI/EFI/OC/config.plist.backup.YYYYMMDD_HHMMSS`
- **Format:** Timestamped (year, month, day, hour, minute, second)
- **Example:** `config.plist.backup.20250930_143052`

### Manual Backup (Recommended)

Before running the script:
```bash
# Backup entire EFI
cp -R /Volumes/EFI/EFI ~/Desktop/EFI_Backup_$(date +%Y%m%d)

# Or just config.plist
cp /Volumes/EFI/EFI/OC/config.plist ~/Desktop/config.plist.backup
```

### Restore from Backup

```bash
# List available backups
ls -lt /Volumes/EFI/EFI/OC/config.plist.backup.*

# Restore specific backup
cp /Volumes/EFI/EFI/OC/config.plist.backup.20250930_143052 /Volumes/EFI/EFI/OC/config.plist
```

---

## 🔧 Advanced Usage

### Custom Firmware Selection

For BrcmFirmwareData.kext vs BrcmFirmwareRepo.kext:
- **BrcmFirmwareData.kext** (default): Works with bootloader injection
- **BrcmFirmwareRepo.kext**: Slightly more memory efficient, install to /S/L/E

To change, edit the script's `determine_required_kexts()` function.

### Boot Arguments (Optional)

Add to OpenCore config.plist → NVRAM → Add → boot-args if needed:

**For BrcmPatchRAM timing issues:**
```
bpr_probedelay=100 bpr_initialdelay=300 bpr_postresetdelay=300
```

**For macOS 12.4+ address conflicts:**
```
-btlfxallowanyaddr
```

**For NVRAM check bypass (macOS ≤14):**
```
-btlfxnvramcheck
```

### Manual Device Detection

If auto-detection fails, identify your device:

```bash
# USB Bluetooth devices
system_profiler SPUSBDataType | grep -A 10 -i bluetooth

# Check vendor/product ID
ioreg -l | grep -i bluetooth
```

Look for entries like:
- `"idVendor" = 0x0a5c` (Broadcom)
- `"idProduct" = 0x21e8` (specific model)

---

## 📚 Additional Resources

### Documentation
- [BrcmPatchRAM GitHub](https://github.com/acidanthera/BrcmPatchRAM)
- [OpenCore Configuration Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [IntelBluetoothFirmware GitHub](https://github.com/OpenIntelWireless/IntelBluetoothFirmware)

### Community Support
- [InsanelyMac BrcmPatchRAM Topic](https://www.insanelymac.com/forum/topic/339175-brcmpatchram2-for-1015-catalina-broadcom-bluetooth-firmware-upload/)
- [r/Hackintosh Discord](https://discord.gg/Wxam8aH)

### Related Tools
- [ProperTree](https://github.com/corpnewt/ProperTree) - Plist editor
- [OpenCore Configurator](https://mackie100projects.altervista.org/opencore-configurator/)
- [Hackintool](https://github.com/headkaze/Hackintool)

---

## ⚠️ Important Notes

### Before Installation
- ✅ **Backup your EFI** partition completely
- ✅ **Have a bootable USB** ready in case of issues
- ✅ **Know your device type** (Intel vs Broadcom)
- ✅ **Check macOS version** compatibility

### After Installation
- ✅ **Reboot required** for changes to take effect
- ✅ **Check Bluetooth version** in System Information
- ✅ **Test sleep/wake** functionality
- ✅ **Verify continuity features** if using Handoff/AirDrop

### Compatibility
- ❌ **Don't mix** BrcmPatchRAM versions (use only one)
- ❌ **Don't use** BrcmBluetoothInjector with BlueToolFixup
- ❌ **Don't install** both BrcmFirmwareData and BrcmFirmwareRepo
- ✅ **Always** match kexts to your macOS version

---

## 🤝 Contributing

Found a bug or want to improve the script?
- Report issues with detailed system information
- Include system logs and config.plist (sanitized)
- Specify macOS version and Bluetooth device model

---

## 📄 License

This script is provided as-is for use with OpenCore Hackintosh systems.

**Credits:**
- BrcmPatchRAM: [Acidanthera](https://github.com/acidanthera/BrcmPatchRAM)
- IntelBluetoothFirmware: [OpenIntelWireless](https://github.com/OpenIntelWireless)
- BlueToolFixup: [Acidanthera](https://github.com/acidanthera/BrcmPatchRAM)

---

## 🎯 Quick Reference

### Most Common Setup

**Intel Bluetooth (macOS 12+):**
```
Required: IntelBluetoothFirmware.kext + BlueToolFixup.kext
NVRAM: Yes (automatically configured)
```

**Broadcom PatchRAM (macOS 12+):**
```
Required: BrcmPatchRAM3.kext + BrcmFirmwareData.kext + BlueToolFixup.kext
NVRAM: Yes (automatically configured)
```

**Broadcom PatchRAM (macOS 10.15):**
```
Required: BrcmPatchRAM3.kext + BrcmFirmwareData.kext + BrcmBluetoothInjector.kext
NVRAM: No
```

---

## 📞 Getting Help

**Before asking for help, please provide:**
1. macOS version
2. Bluetooth device vendor/product ID
3. Output from: `kextstat | grep -i bluetooth`
4. System logs: `log show --last boot | grep -i brcm`
5. Bluetooth firmware version from System Information

**Script execution log:**
```bash
./BluetoothFixup.command 2>&1 | tee install_log.txt
```

This saves all output for troubleshooting.

---

**Happy Hackintoshing! 🎉**

---

Made with ♥️ by Jaimin