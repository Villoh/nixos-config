# Desktop installation

Install or update the existing `desktop` host from a checkout of this repository. Its generated hardware file is already at `hosts/desktop/hardware-configuration.nix`; do not use it on another machine.

## Validate and test

```bash
cd /path/to/nixos-config
nix flake check
sudo nixos-rebuild test --flake .#desktop
```

`test` activates the generation temporarily without changing the boot default. Verify:

- DankGreeter offers Hyprland and the session starts.
- DMS, networking, audio, Bluetooth, notifications, locking, and Wayland portals work.
- zram is active and no disk- or file-backed swap is enabled:

```bash
zramctl
swapon --show
```

## Review and switch

Review repository changes before applying them. Home Manager is configured to preserve existing files with a `.bak` suffix on first ownership.

```bash
git diff --stat
git diff
sudo nixos-rebuild switch --flake .#desktop
```

Do not delete `.bak` files or switch before the check and temporary test pass.

## DMS first login

After entering Hyprland for the first time, deploy DMS compositor defaults:

```bash
dms setup headless --compositor hyprland --skip-existing
```

Optional per-area setup commands are `dms setup binds`, `colors`, `layout`, `outputs`, `windowrules`, and `cursor`. DMS files are written under `~/.config/hypr/dms/`; do not manage those same files with chezmoi or Home Manager.

DMS starts through Home Manager's `hyprland-session.target`. Do not also add `dms run` to Hyprland startup: that can launch two DMS instances.

## Recovery

If Hyprland or DankGreeter fails:

1. Select an earlier generation from the boot menu.
2. If available, select an older SDDM/Plasma generation.
3. From a TTY, fix the checkout and test again before switching:

```bash
sudo nixos-rebuild test --flake .#desktop
```

Systemd-boot keeps up to five entries. Clean old store data only after confirming rollback generations are no longer needed:

```bash
sudo nix-collect-garbage --delete-older-than 30d
```
