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
  url = "github:nix-community/lanzaboote/v1.2.0";
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

### Desktop procedure (ASUS ROG STRIX X570-E)

Lanzaboote is configured in `hosts/desktop/default.nix` (input `lanzaboote` v1.2.0, `boot.lanzaboote`, `pkgs.sbctl`) and Secure Boot is enabled on this host (`Secure Boot: enabled (user)`, vendor keys `microsoft`). This is the procedure that was used, kept for reinstalls and recovery. Before it, the firmware reported `Secure Boot: disabled (setup)`, so no Platform Key existed and no BIOS step was needed before enrolling.

1. **Back up** the ESP and keep recovery media at hand:

   ```bash
   sudo tar -czf ~/esp-backup.tar.gz -C /boot .
   ```

2. **Create keys before the first rebuild** (the Lanzaboote installer signs with them and fails without them):

   ```bash
   nix shell nixpkgs#sbctl -c sh -c 'sudo "$(command -v sbctl)" create-keys'
   sudo tar -czf ~/sbctl-keys-backup.tar.gz -C /var/lib sbctl
   ```

   Move the keys backup to secure external storage and delete the local copy. Never commit it.

3. **Install Lanzaboote with Secure Boot still off** and verify:

   ```bash
   nh os boot .#desktop
   sudo sbctl verify
   ```

   `nh os boot` does not activate the new generation, so `sbctl` is not in `PATH` yet. Run it from the new generation (`<result>/sw/bin/sbctl`, path printed after `>>>`) or with `nix shell nixpkgs#sbctl`.

   `/boot/EFI/BOOT/BOOTX64.EFI`, `/boot/EFI/systemd/systemd-bootx64.efi` and `/boot/EFI/Linux/nixos-generation-*.efi` must be signed. These are expected to be reported unsigned, because they are not signed with your key:

   - `/boot/EFI/nixos/kernel-*.efi`: the Lanzaboote stub checks its hash.
   - `/boot/EFI/Microsoft/**`: Microsoft signs these, and `--microsoft` makes the firmware trust them. The `.dll` and `.mui` files are not EFI binaries.
   - `/boot/EFI/systemd/systemd-boot-fallbackx64.efi`: leftover from the stock installer; no firmware boot entry points to it.

4. **Reboot** with Secure Boot still disabled and confirm NixOS boots from `nixos-generation-N-*.efi` (`bootctl status`, `Current Entry`). A `Secure Boot is not enabled` warning at this point is expected. Check Windows too (`sudo bootctl set-oneshot auto-windows && reboot`).

   Then remove the stale entries left by the stock installer. Under Secure Boot they would fail because their kernel is unsigned:

   ```bash
   sudo rm /boot/loader/entries/nixos-*.conf
   ```

5. **Enroll keys**, keeping Microsoft certificates (the Windows boot manager and the GPU Option ROM are signed by Microsoft):

   ```bash
   sudo sbctl enroll-keys --microsoft
   ```

   `--microsoft` includes the 2011 and 2023 Microsoft certificates, which covers the Windows boot manager copied to `/boot/EFI/Microsoft`.

6. **BIOS:** reboot into firmware setup and, under Boot > Secure Boot, set `OS Type` to `Windows UEFI Mode` (with `Other OS`, Secure Boot stays off). Do **not** use "Clear Secure Boot Keys" or "Reset to default", which drop the enrolled keys or `dbx`. Save and exit.

7. **Verify:** `bootctl status` must show `Secure Boot: enabled (user)`. Boot NixOS and Windows (`sudo bootctl set-oneshot auto-windows && reboot`). Check that the NVIDIA driver still loads (`nvidia-smi`); this kernel has no lockdown LSM, so unsigned modules are accepted.

**Known gap:** this firmware has no active `dbx` (only `dbxDefault` exists in `/sys/firmware/efi/efivars/`), so Microsoft-signed binaries that were revoked are still accepted. `sbctl enroll-keys` cannot populate it (`--firmware-builtin` only takes `db`, `KEK` and `PK`). `fwupd` is not a fix today: its `uefi_dbx` plugin only appends to an existing `dbx` variable and disables itself when it is missing ([fwupd#6626](https://github.com/fwupd/fwupd/issues/6626), open). Left as is deliberately: the exposure needs physical write access to the unencrypted ESP. Revisit when that issue is fixed, and check first that the Windows boot manager copied to `/boot/EFI/Microsoft` is not one the current Microsoft `dbx` revokes.

**Rollback:** if something does not boot, disable Secure Boot in the BIOS. The signed entries still boot with it off. Lanzaboote keeps the last `configurationLimit` (5) generations.

If `bootctl status` still shows `Default Entry: @saved` from the old setting, clear the EFI variable with `sudo bootctl set-default ""` (an empty ID unsets it, per `man bootctl`). Lanzaboote's default is `nixos-*`, which selects the newest generation.

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
