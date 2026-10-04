# Secure Boot on NixOS

NixOS documents two maintained Secure Boot integrations: [Lanzaboote](https://wiki.nixos.org/wiki/Lanzaboote) and [Limine](https://wiki.nixos.org/wiki/Limine). Keeping stock systemd-boot and signing files manually with `sbctl` is also possible, but NixOS does not automate that signing across rebuilds.

This host boots in UEFI mode with systemd-boot and uses an encrypted root. Check the current state before changing boot configuration:

```bash
bootctl status
```

Bootloader changes belong in `hosts/desktop/default.nix`, not shared core.
Before any permanent installation or key enrollment below, obtain explicit
approval, back up the NixOS ESP and current boot configuration, and prepare
recovery media. Do not execute these steps automatically. `nh os test` can
check runtime activation, but cannot install or test a new bootloader.

Keep Secure Boot disabled until selected bootloader is installed and its EFI binaries are signed. Firmware Setup Mode is vendor-specific: follow motherboard manual, preserve `dbx`, and keep firmware-builtin keys if hardware Option ROMs or vendor firmware updates need them. Keep Microsoft certificates enrolled for Windows. Store private keys from `/var/lib/sbctl` securely; never commit them.

`sbctl` creates and enrolls keys, signs EFI files, and verifies signatures. If it is not installed yet, run it temporarily, for example:

```bash
nix shell nixpkgs#sbctl -c sh -c 'sudo "$(command -v sbctl)" create-keys'
```

## Option A: Lanzaboote (recommended)

Lanzaboote integrates signing into NixOS boot generation and retains the systemd-boot menu format. It requires UEFI, systemd-boot, and nixpkgs unstable. For this host, keep the copied `/boot/EFI/Microsoft` directory described in [Windows dual boot](./dual-boot-windows.md), and do not create a manual `windows.conf` entry.

Add the flake input:

```nix
lanzaboote = {
  url = "github:nix-community/lanzaboote/v1.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import `inputs.lanzaboote.nixosModules.lanzaboote` in `hosts/desktop/default.nix`.
Update that host's existing boot settings (do not duplicate attributes):

```nix
{ lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  environment.systemPackages = [ pkgs.sbctl ];
}
```

With Secure Boot still disabled, validate the flake, create keys before rebuilding, activate Lanzaboote, and verify its EFI outputs:

```bash
nix flake lock
nix flake check
nix shell nixpkgs#sbctl -c sh -c 'sudo "$(command -v sbctl)" create-keys'
nh os switch . -H desktop
sudo sbctl verify
```

Check that Lanzaboote's EFI stubs/generations are signed. Some raw kernel files may be reported unsigned. Once verified, enter firmware Setup Mode using the board-specific procedure, boot back into NixOS, and enroll keys while retaining Microsoft certificates:

```bash
sudo sbctl enroll-keys --microsoft
```

Use `--firmware-builtin` too only if vendor guidance requires preserving OEM certificates. Reboot; enable Secure Boot in firmware if enrollment did not enable it. Confirm with `bootctl status` (`Secure Boot: enabled (user)`) and test both NixOS and Windows.

## Option B: systemd-boot with manual `sbctl` signing

This keeps `boot.loader.systemd-boot.enable = true`, with no Lanzaboote input. Add `pkgs.sbctl` to `environment.systemPackages`, keep Secure Boot disabled, and install that configuration. Create keys, identify the actual loader and kernel EFI paths using `bootctl status` and `bootctl list`, then sign them:

```bash
nix flake check
nh os switch . -H desktop
sudo sbctl create-keys
sudo sbctl sign --save /boot/EFI/systemd/systemd-bootx64.efi
sudo sbctl sign --save /boot/EFI/nixos/<current-kernel-efi-file>
sudo sbctl verify
```

Paths vary. Sign the fallback EFI loader too if firmware can boot it. After verification, enter Setup Mode and enroll keys with Microsoft certificates:

```bash
sudo sbctl enroll-keys --microsoft
```

Reboot and enable Secure Boot in firmware. After **every** NixOS rebuild, sign overwritten boot files and any newly generated kernel EFI file before rebooting. `sbctl` tracks paths, but NixOS kernel filenames change across versions, so `sbctl sign-all` alone can miss new kernels.

This is a custom, high-maintenance option. Stock systemd-boot loads initrd and command line separately; signing only the kernel does not authenticate those files. Prefer Lanzaboote for automated NixOS signing or use a signed unified image if deliberately maintaining a custom setup.

## Option C: Limine

Limine's Secure Boot integration is provided by NixOS and needs no external flake input. It replaces systemd-boot; test Limine's boot menu and recovery path while Secure Boot remains disabled. Configure the desktop host with:

```nix
{ lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sbctl ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.enable = true;
  boot.loader.limine.secureBoot.enable = false;
}
```

Run `nix flake check`, create keys with the temporary `nix shell` command above, then install Limine with Secure Boot off:

```bash
nh os switch . -H desktop
```

Reboot and confirm Limine boots NixOS; keep a recovery route because this changes bootloader. Then follow the board-specific Setup Mode procedure, boot back into NixOS, and enroll keys. NixOS's Limine guide uses Microsoft and firmware-builtin certificates:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Set `boot.loader.limine.secureBoot.enable = true`, validate again, then activate the signed configuration:

```bash
nix flake check
nh os switch . -H desktop
sudo sbctl verify
```

Reboot and verify `bootctl status`. Windows menu configuration is separate because its EFI System Partition is on another disk; retain the firmware's Windows Boot Manager entry as fallback. See [Windows dual boot](./dual-boot-windows.md).

## References

- [NixOS Secure Boot overview](https://wiki.nixos.org/wiki/Secure_Boot)
- [Lanzaboote preparation guide](https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html)
- [Lanzaboote firmware/enrollment guide](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html)
- [NixOS Limine guide](https://wiki.nixos.org/wiki/Limine)
- [`sbctl` signing workflow](https://github.com/Foxboron/sbctl/blob/master/docs/sbctl.8.txt)
