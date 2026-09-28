# NixOS + Hyprland + DMS

Reproducible NixOS configuration for the `desktop` and `zenbook` hosts.
Hyprland, DMS, and DankGreeter provide the graphical session. Each machine has
its own generated hardware configuration; never reuse one host's hardware file
on another machine.

## Installation guides

- [Desktop](docs/installation-desktop.md)
- [Zenbook laptop](docs/installation-laptop.md)
- [Maintenance and updates](docs/maintenance.md)

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
sudo nixos-rebuild test --flake .#desktop
```

`test` activates the generation temporarily and does not change the boot
configuration. Verify that DankGreeter offers the Hyprland session, DMS starts
inside Hyprland, and networking, audio, Bluetooth, notifications, locking, and Wayland
portals work. Swap policy is host-specific: desktop uses compressed zram swap
with no disk-backed swap; Zenbook uses zswap with persistent swap declared by
its generated hardware configuration.

Check desktop zram with:

```bash
zramctl
swapon --show
```

zram should be present, with no disk or file-backed swap. zswap requires a
persistent swap device to cache into; hibernation additionally needs real
persistent swap and matching resume configuration.

## DMS compositor setup

The DMS module installs the shell and its dependencies, but compositor-specific
configuration is deployed separately. After entering Hyprland for the first
time, deploy the defaults with:

```bash
dms setup headless --compositor hyprland --skip-existing
```

Individual files can also be deployed with `dms setup binds`, `dms setup
colors`, `dms setup layout`, `dms setup outputs`, `dms setup windowrules`, and
`dms setup cursor`. These files live under `~/.config/hypr/dms/`. Do not manage
the same files with chezmoi or Home Manager.

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

The desktop profile includes Steam with a Gamescope session and Proton-GE,
Lutris, Heroic, Wine/Winetricks, ProtonUp-Qt, ProtonPlus, MangoHud, and
GOverlay. GameMode is enabled as well.

Additional Proton versions, including Proton-CachyOS when available through
the selected compatibility-tool manager, Wine runners, and per-launcher
settings should be managed from ProtonUp-Qt, ProtonPlus, Lutris, or Heroic in
the user session. These are user
environment settings and are not pinned in NixOS.

Do not modify or copy the desktop `hardware-configuration.nix` to another
machine. The future `zenbook` host must have its own hardware configuration and
persistent encrypted swap if hibernation is required.
