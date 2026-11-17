# nixos-config

Reproducible NixOS configuration built on flakes: Hyprland (UWSM) with
[Dux Shell](https://danklinux.com) (DMS) and Dux Greeter, Home Manager for personal
settings, and a handful of own packages.

| Host | State | Notes |
| --- | --- | --- |
| `desktop` | Active, exposed by the flake | Ryzen + NVIDIA, Lanzaboote Secure Boot, Windows dual boot, gaming. Hostname `nixos`. |
| `zenbook` | Written, **off** until its hardware file exists | Intel laptop with Thunderbolt NVIDIA eGPU. Its flake output is commented out in `flake.nix`. |

Never reuse one host's `hardware-configuration.nix` on another machine.

## Quick start

```bash
nix develop                   # git, gh, Node.js 24, nixfmt, nil, statix
nix flake check               # evaluate every exposed host
nh os test . -H desktop       # activate temporarily; boot default is untouched
```

Review `git diff` first. `switch` and `boot` are manual decisions: see
[maintenance](docs/maintenance.md). An Android emulator shell is also available with
`nix develop .#android`.

## Repository layout

```text
flake.nix            inputs, overlay, hosts and dev shells
hosts/<host>/        hardware, hostname, bootloader, display, optional services
profiles/            reusable NixOS compositions (desktop, laptop, gaming)
modules/nixos/       system modules: core, hardware, desktop, gaming, services
modules/home/        Home Manager modules: cloud, communication, core, desktop,
                     development, gaming, media, security, shell, terminals
users/<user>/        account (NixOS) and home (Home Manager) composition
packages/            own packages and temporary prebuilt releases
shells/              extra dev shells (Android emulator)
docs/                guides, see below
```

See [architecture](docs/architecture.md) for how the layers fit and who owns what.

## What the desktop session is

- **Compositor**: Hyprland, started by UWSM, configured in Lua.
- **Shell**: Dux Shell (DMS), bound to `graphical-session.target`. Noctalia is an
  alternative shell, prepared but off.
- **Login**: Dux Greeter with the `Hyprland (uwsm-managed)` session.
- **First login needs no setup**: `dms-hyprland-init` seeds missing files in
  `~/.config/hypr/` and never overwrites existing ones. Details in
  [architecture](docs/architecture.md#ownership-and-smoke-checks).

## Documentation

| Topic | Guide |
| --- | --- |
| Install or update the desktop | [installation-desktop](docs/installation-desktop.md) |
| Install the Zenbook | [installation-laptop](docs/installation-laptop.md) |
| Layers, users, new hosts, Noctalia | [architecture](docs/architecture.md) |
| Updates, `nh`, recovery, cleanup | [maintenance](docs/maintenance.md) |
| Secure Boot (Lanzaboote) | [secure-boot](docs/secure-boot.md) |
| Windows dual boot | [dual-boot-windows](docs/dual-boot-windows.md) |
| Gaming (Steam, Proton, Gamescope) | [gaming](docs/gaming.md) |

Agent and contribution rules live in [AGENTS.md](AGENTS.md).

## Conventions

- Conventional Commits; `flake.lock` stays committed.
- Dotfiles, scripts and secrets belong to chezmoi, not to this repository.
- Updates go through [nixup](https://github.com/Villoh/nixup), reported weekly by the
  `updates` GitHub workflow.
- No secrets, keys or machine-local state in the repository.
