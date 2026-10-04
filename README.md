# NixOS + Hyprland + DMS

Reproducible NixOS configuration for `desktop`, with a future `zenbook` host.
Only `desktop` is exposed by the flake; Zenbook still needs its own generated
hardware configuration. Never reuse one host's hardware file on another machine.
Hyprland, DMS, and DankGreeter provide a shared session without requiring a
personal Home Manager profile.

## Installation guides

- [Desktop](docs/installation-desktop.md)
- [Zenbook laptop](docs/installation-laptop.md)
- [Windows dual boot](docs/dual-boot-windows.md)
- [Secure Boot](docs/secure-boot.md)
- [Maintenance and updates](docs/maintenance.md)
- [Architecture, users, and ownership](docs/architecture.md)

## Development shell

Enter the reproducible repository environment instead of installing temporary
host tools:

```bash
nix develop
```

It provides Git, GitHub CLI, Node.js 24, `nixfmt`, `nil`, and `statix`.

## Validation

```bash
nix flake check
nh os test . -H desktop
```

Review `git diff` before activation. `test` activates the generation temporarily
and does not change the boot configuration. Verify that DankGreeter offers the
Hyprland session, DMS starts inside Hyprland, and networking, audio, Bluetooth,
notifications, locking, and Wayland portals work. Swap policy is host-specific:
desktop uses compressed zram swap with no disk-backed swap; Zenbook's zswap
requires persistent swap in its future generated hardware configuration.

Check desktop zram with:

```bash
zramctl
swapon --show
```

zram should be present, with no disk or file-backed swap. zswap requires a
persistent swap device to cache into; hibernation additionally needs real
persistent swap and matching resume configuration.

## DMS compositor startup

No `dms setup` step is required after login. NixOS provides
`dms-hyprland-init`, run as the user by UWSM's `wayland-wm@` `ExecStartPre`
after environment preparation, only for Hyprland sessions and before the
compositor and DMS. It copies pinned DMS defaults into missing fragments under
`$XDG_CONFIG_HOME/hypr/dms/` (default `~/.config/hypr/dms/`), private and
writable, and creates a personal Lua main only if absent. Existing files,
including empty files, malformed Lua, and dangling symlinks, are not replaced.
If legacy `hyprland.conf` exists without a Lua main, initialization does nothing.
Outside UWSM, run `dms-hyprland-init` explicitly if needed.

Nix inlines six literal DMS imports from
`modules/nixos/desktop/hyprland-base.lua` into both the shared main template and
Home Manager's personal main; this is not a runtime loader. Each requires
`/etc/xdg/hypr/host` once, after DMS imports and personal preferences where
present. No global `hyprland.lua` or `dms-base.lua` is installed under
`/etc/xdg/hypr/`. Initialization creates new user files, but never replaces
existing HM/DMS/chezmoi configuration or adds `binds-user.lua`. See
[ownership and smoke checks](docs/architecture.md#ownership-and-smoke-checks).

DMS is bound to UWSM's `graphical-session.target` in
`modules/nixos/desktop/dms.nix`, so it starts with the logged-in Hyprland
session. DankGreeter runs a separate temporary compositor for the login screen;
the selected `Hyprland (uwsm-managed)` session launches the desktop through
UWSM. We deliberately do not also run `dms run` from `hyprland.lua`, because
DMS documents that using both startup methods can launch two instances.

References:

- [DMS Hyprland compositor setup](https://danklinux.com/docs/dankmaterialshell/compositors/)
- [DMS Hyprland systemd integration](https://danklinux.com/docs/dankmaterialshell/installation/#hyprland)
- [DMS setup CLI](https://danklinux.com/docs/dankmaterialshell/cli-setup/)

## Gaming

The desktop host opts into NixOS gaming support: 32-bit graphics/audio,
controller udev rules, GameMode, and a Gamescope session. `programs.steam.enable`
stays false, so this does not install Steam globally. GameMode remains a host
opt-in; Mikel's groups stay `wheel`, `networkmanager`, `docker`, and `al68`,
without adding `gamemode` or expanding his permissions.

Only Mikel's desktop Home Manager profile imports `modules/home/gaming`,
providing Steam, Proton-GE, Lutris, Heroic, Wine/Winetricks, ProtonUp-Qt,
ProtonPlus, MangoHud, and GOverlay. Its Steam wrapper discovers Proton-GE.
The `Steam (user profile)` Gamescope session launches the logged-in user's
Steam and reports an error if that user has no Steam installed. Other users
and the Zenbook do not inherit these clients.

Additional Proton versions, including Proton-CachyOS when available through
the selected compatibility-tool manager, Wine runners, and per-launcher
settings should be managed from ProtonUp-Qt, ProtonPlus, Lutris, or Heroic in
the user session. These are user
environment settings and are not pinned in NixOS.

Do not modify or copy the desktop `hardware-configuration.nix` to another
machine. The future `zenbook` host must have its own hardware configuration and
persistent encrypted swap if hibernation is required.
