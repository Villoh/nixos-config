# Dual boot with Windows

This guide covers NixOS and Windows/AtlasOS installed on separate disks, each with its own EFI System Partition (ESP). `/boot` must be mounted to the NixOS ESP. Do not format, copy over, or modify Windows' original ESP as part of NixOS installation.

## systemd-boot (current desktop setup)

systemd-boot loads EFI binaries from its own ESP; it cannot directly launch Windows' boot manager from an ESP on another disk. Copy Windows' Microsoft boot files to the NixOS ESP so systemd-boot can auto-detect them.

Identify the Windows ESP by filesystem, label, and PARTUUID; do not guess device names, which can change between boots:

```bash
lsblk -o NAME,FSTYPE,PARTUUID,LABEL,MOUNTPOINTS
findmnt /boot
```

Confirm `/boot` is the NixOS ESP. Mount the Windows ESP read-only using its PARTUUID, then copy the Microsoft directory:

```bash
sudo mkdir -p /mnt/windows-esp
sudo mount -o ro /dev/disk/by-partuuid/<WINDOWS-ESP-PARTUUID> /mnt/windows-esp
sudo mkdir -p /boot/EFI/Microsoft
sudo cp -a /mnt/windows-esp/EFI/Microsoft/. /boot/EFI/Microsoft/
sudo umount /mnt/windows-esp
```

Do **not** create `/boot/loader/entries/windows.conf`. With the copied `EFI/Microsoft/Boot/bootmgfw.efi`, systemd-boot auto-discovers Windows on the next boot. A manual entry for the same EFI binary creates a duplicate menu option. Check `bootctl list` after reboot. If a previous manual `windows.conf` exists, remove or rename that file, but keep `/boot/EFI/Microsoft`; removing the copy makes the automatic menu option disappear.

The motherboard's NVRAM Windows Boot Manager entry remains a separate fallback and points to the original Windows ESP. The copied files on `/boot` are only for systemd-boot's menu. Windows updates that replace its boot files may require copying `EFI/Microsoft` to `/boot` again.

If Windows appears in the menu but does not boot, disable UEFI Fast Boot. This is separate from Windows Fast Startup.

## GRUB with os-prober (alternative)

GRUB can probe other disks and add Windows to its menu at rebuild time. This changes the bootloader from systemd-boot and should be tested with Secure Boot disabled first. Because the shared core module enables systemd-boot, force it off when enabling GRUB:

```nix
{ lib, ... }:
{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev"; # UEFI, not MBR
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

Run `nix flake check`, then `sudo nixos-rebuild test --flake .#desktop`. Verify GRUB detects and boots Windows before using `sudo nixos-rebuild switch --flake .#desktop`. Re-run rebuild after Windows bootloader changes; os-prober results are generated during activation. Keep the firmware Windows Boot Manager entry as a fallback.

## Secure Boot

For Secure Boot with the current systemd-boot-style menu, use Lanzaboote and retain the copied Microsoft files on `/boot`. Enroll Microsoft's signing certificates so Windows remains bootable. GRUB and Limine require their own boot-entry and signing setup. See [Secure Boot on NixOS](./secure-boot.md).
