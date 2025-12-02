# Minimal UEFI Linux

These are the scripts for building a simple Linux system consisting of one file with a size of approximately 2.5 MB.

You must only put the file `/ESP/EFI/BOOT/BOOTX64.EFI` into the `\EFI\BOOT\` directory on your flash drive partition formatted as FAT32, disable Secure Boot, and boot from the flash drive.

# How to build

On Windows 10 / Windows 11:

1. Install Docker if not installed
1. Run `build.bat`

On Linux / macOS:

1. Install Docker if not installed
1. Run `./build.sh`

