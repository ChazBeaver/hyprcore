# HyprCore: Create a Bootable Arch Linux USB

This document explains how to create a bootable Arch Linux USB from any Linux system.
It includes command steps, example outputs, dependencies, common pitfalls, and verification.

This guide assumes:
- You are using Linux (NixOS or any major distro).
- You have downloaded the Arch Linux ISO.
- You have a USB device dedicated to this purpose.

============================================================================
# Step 1: Download the Latest Arch ISO
============================================================================

Visit the official Arch Linux download page:
https://archlinux.org/download

Recommended file:
archlinux-YYYY.MM.DD-x86_64.iso

Example wget command:
wget https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso

Example file after download:
~/Downloads/archlinux-2025.11.01-x86_64.iso

============================================================================
# Step 2: Identify Your USB Device (Critical Safety Step)
============================================================================

Run:
lsblk -fp

Example output BEFORE wiping:
/dev/sda   iso9660  nixos-installer...
/dev/sdb   28.8G    (THIS is your USB)
/dev/nvme0n1...

The USB will typically appear as:
/dev/sda  OR /dev/sdb  OR /dev/sdc

Verify size (8GB/16GB/32GB/64GB).
Verify model (often shows in MODEL column).

***NEVER proceed until fully certain which device is the USB.***

============================================================================
# Step 3: Install Dependencies (NixOS Example)
============================================================================

On NixOS:
nix-shell -p gptfdisk

This gives you access to `sgdisk`, used for wiping partition tables.

On Ubuntu/Debian:
sudo apt install gdisk

On Fedora:
sudo dnf install gdisk

============================================================================
# Step 4: Wipe the USB Completely
============================================================================

WARNING: This WILL erase the entire USB.

1. Remove filesystem signatures
sudo wipefs -a /dev/sdX

Example output:
/dev/sda: 5 bytes erased at offset...

2. Zap all partitions and tables
sudo sgdisk --zap-all /dev/sdX

3. Create a new GPT table
sudo sgdisk -o /dev/sdX

Example confirmation:
GPT data structures destroyed and initialized.

============================================================================
# Step 5: Flash the Arch ISO Using “dd” (Recommended Method)
============================================================================

Replace <path> with your actual ISO path, example:
~/Downloads/archlinux-2025.11.01-x86_64.iso

Command:
sudo dd if=<path-to-iso>.iso of=/dev/sdX bs=4M status=progress conv=fsync

Example:
sudo dd if=~/Downloads/archlinux-2025.11.01-x86_64.iso of=/dev/sda bs=4M status=progress conv=fsync

Example output:
363+1 records in
363+1 records out
1526038528 bytes copied, 14.4 s, 105 MB/s

Force write buffers to flush:
sync

============================================================================
# Step 6: Verify the USB Was Flashed Correctly
============================================================================

Run:
lsblk -fp

Expected correct output after flashing:
/dev/sdX         iso9660  ARCH_202511 2025-11-01-09-48-56-00
├─/dev/sdX1      iso9660  ARCH_202511 2025-11-01-09-48-56-00
└─/dev/sdX2      vfat     ARCHISO_EFI 6905-D788

This proves:
✔ ISO is written correctly
✔ Partitions look exactly like an official Arch installer
✔ USB is bootable in both BIOS and UEFI

============================================================================
# Step 7: Boot From the USB
============================================================================

- Reboot your system
- Enter BIOS/UEFI
- Select the USB labeled “ARCH_2025XX”

If secure boot is enabled, disable it unless you use shim or custom keys.

============================================================================
# Troubleshooting Section
============================================================================

***Issue: USB does not appear in lsblk***
- Reinsert USB
- Try a different port (preferably a USB 3.0 port)
- Run: dmesg | grep -i usb

***Issue: dd finishes instantly with very low bytes copied***
- ISO path incorrect
- USB path incorrect

***Issue: Permission denied or input/output error***
- Ensure you used 'sudo'
- The USB may be locked or failing

***Issue: USB won’t boot on target machine***
- Ensure flashed using dd, not cp
- Disable secure boot
- Try a different port

============================================================================
# Process Complete
============================================================================

Your USB is now a fully functional Arch Linux installation media.
Next guide: Partitioning & Installing the HyprCore Base System.
