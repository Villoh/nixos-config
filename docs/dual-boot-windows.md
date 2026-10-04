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

GRUB can probe other disks and add Windows to its menu during bootloader
installation. This replaces systemd-boot and must first be tested with Secure
Boot disabled. Bootloader selection belongs to `hosts/desktop/default.nix`,
not shared core. Edit its existing loader settings to disable systemd-boot
when enabling GRUB:

```nix
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev"; # UEFI, not MBR
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

Review `git diff`, run `nix flake check`, then use `nh os test . -H desktop`
for runtime checks. **`test` does not install GRUB or change the boot menu**, so
it cannot verify Windows detection or booting through GRUB.

Before installing GRUB, back up the NixOS ESP and current boot configuration,
keep recovery media and the firmware Windows Boot Manager fallback available,
and obtain explicit approval for this permanent bootloader change. Only then
run `nh os boot . -H desktop` to install the selected boot configuration and
reboot with Secure Boot disabled. Check both NixOS and Windows from GRUB;
use the recovery route if either fails. Reinstall the boot configuration after
relevant Windows bootloader changes to refresh os-prober results. Never run
this permanent step automatically.

## Secure Boot

For Secure Boot with the current systemd-boot-style menu, use Lanzaboote and retain the copied Microsoft files on `/boot`. Enroll Microsoft's signing certificates so Windows remains bootable. GRUB and Limine require their own boot-entry and signing setup. See [Secure Boot on NixOS](./secure-boot.md).
