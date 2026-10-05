# Desktop installation

Install or update the existing `desktop` host from a checkout of this repository. Its generated hardware file is already at `hosts/desktop/hardware-configuration.nix`; do not use it on another machine.

## Validate and test

```bash
cd /path/to/nixos-config
nix flake check
git diff
nh os test . -H desktop
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
nh os switch . -H desktop
```

Do not delete `.bak` files or switch before the check and temporary test pass.
`switch` is a permanent boot-default change; run it only with explicit approval.

## DMS first login

No `dms setup` command is needed. Before Hyprland starts, UWSM runs
`dms-hyprland-init` as the user. It creates missing writable DMS fragments under
`$XDG_CONFIG_HOME/hypr/dms/` (default `~/.config/hypr/dms/`) from pinned defaults,
and a personal Lua main only if absent. Existing HM/DMS/chezmoi files and
symlinks remain untouched, including empty files and dangling links. A legacy
`hyprland.conf` without a Lua main causes initialization to do nothing.
There is no global `/etc/xdg/hypr/hyprland.lua` fallback. Outside UWSM, run
`dms-hyprland-init` explicitly if needed. See
[architecture and smoke checks](architecture.md#ownership-and-smoke-checks).

DMS starts through UWSM's `graphical-session.target`. Select
`Hyprland (uwsm-managed)` in DankGreeter. Do not also add `dms run` to
Hyprland startup: that can launch two DMS instances.

## Recovery

If Hyprland or DankGreeter fails:

1. Select an earlier generation from the boot menu.
2. If available, select an older SDDM/Plasma generation.
3. From a TTY, fix the checkout and test again before switching:

```bash
nh os test . -H desktop
```

Systemd-boot keeps up to ten entries. See [Maintenance: recovery](maintenance/recovery.md)
for generation rollback, and [Maintenance: cleanup](maintenance/cleanup.md) before
removing old generations or collecting the Nix store.
