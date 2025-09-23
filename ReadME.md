# BluetoothFixup Installer

**Version:** 1.0
**Author:** Jaimin

---

## Overview

BluetoothFixup Installer is a **macOS script-based tool** for installing required Bluetooth kexts to your OpenCore EFI.

Currently supported:

* **Intel Bluetooth** (BlueToolFixup.kext, IntelBluetoothFirmware.kext)
* **Broadcom dongles** (coming soon)

It mounts your EFI, copies the kexts, and updates your `config.plist` automatically.

---

## Requirements

* macOS 10.15 or newer
* OpenCore EFI installed at `/Volumes/EFI/EFI/OC`
* Terminal access and admin password

---

## Installation Steps

1. Open Terminal.
2. Clone the repository:

   ```bash
   git clone https://github.com/jai-git4208/BluetoothFixup/
   ```
3. Navigate into the folder:

   ```bash
   cd BluetoothFixup
   ```
4. Run the installer script:

   ```bash
   ./BluetoothFixup.command
   ```

> ⚠️ Enter your password when prompted. The script will mount the EFI and copy the kexts.

---

## Notes

* For Intel Bluetooth, the kexts installed are:

  * `BlueToolFixup.kext`
  * `IntelBluetoothFirmware.kext`
* Broadcom support is under development and will be included in future releases.
* The script **does not modify any files outside the EFI folder**.
* It’s safe to run multiple times, but **back up your EFI** before running.
* Ensure your EFI is mounted at `/Volumes/EFI`.
* Ensure you have python3 installed.

---

## License

Made with ♥️ by **Jaimin** — free for personal use.
