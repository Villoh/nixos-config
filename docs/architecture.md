# Architecture and ownership

## Layers

- `hosts/<host>/`: hardware, hostname, bootloader, system state version, physical
  display/keyboard settings, optional services, and user/profile selection.
  `desktop` retains hostname `nixos`; its bootloader values are unchanged.
- `profiles/`: reusable compositions of NixOS capabilities, not personal apps.
- `modules/nixos/`: shared system services and session infrastructure. Core
  enables `nh`; desktop supplies Hyprland/UWSM, DMS, DankGreeter, portals,
  Ghostty, and Qt/Breeze/qtengine without requiring Home Manager or an account.
- `modules/home/`: Home Manager modules using per-user options directly, not
  NixOS wrappers around `home-manager.users.mikel`. Browsers, application
  preferences, the GPG agent, and personal DMS plugins belong here. The gaming
  module uses `osConfig` to consume host support, not to install a global client.
- `users/mikel/default.nix`: NixOS composition importing `account.nix` and
  assigning `home.nix` to `home-manager.users.mikel`. `account.nix` owns identity,
  shell, and baseline groups; `home.nix` selects personal HM modules/state version.

The former `modules/nixos/core/users.nix` account now lives in
`users/mikel/account.nix`; the former core `state.nix` is now
`hosts/desktop/state.nix`. State versions describe installation compatibility,
not the current package release; do not bump them as part of routine updates.

NVIDIA is an explicit desktop import, not a generic desktop assumption.
Docker, Tailscale, CUPS, Flatpak, and KDE Connect are host opt-ins. Desktop alone
adds Mikel to `docker` and `al68`, alongside baseline `wheel` and
`networkmanager`; another user must not inherit these groups. GameMode remains
a host opt-in, without adding `gamemode` or expanding Mikel's permissions.
Desktop selects NixOS gaming support separately from Mikel's
`modules/home/gaming` import. `programs.steam.enable` remains false; the
Gamescope session resolves Steam from the logged-in user's profile.

## Add a minimal user

A graphical user needs no Home Manager profile. Create `users/guest/account.nix`:

```nix
{ ... }:
{
  users.users.guest.isNormalUser = true;
}
```

Add `../../users/guest/account.nix` to the chosen host's `imports`. Provision
login credentials separately through an approved local mechanism; never commit
passwords or hashes. Do not copy Mikel's groups, plugins, apps, or home directory.
The account can use the shared desktop with automatic UWSM initialization.

For personal declarative settings, optionally add `users/guest/home.nix` with
its own HM state version and selected `modules/home/` imports, then connect it
through `home-manager.users.guest`. The host must import Home Manager and pass
`inputs` through `home-manager.extraSpecialArgs` for modules that need them.
Gaming requires both host gaming support and that user's explicit HM import.

## New host checklist

1. Generate hardware configuration on the actual machine. Never copy desktop's
   file; review disks, encryption, swap/resume, and required GPU drivers.
2. Choose hostname, bootloader, system state version, physical display/keyboard
   settings, profiles, optional services, and accounts under `hosts/<host>/`.
   Do not infer NVIDIA or gaming from the generic desktop profile.
3. Supply shared physical settings through `/etc/xdg/hypr/host.lua`, as desktop's
   `display.nix` and Zenbook's `keyboard.nix` do. Keep preferences in HM.
4. Add a flake output only after the host has its own hardware file. Zenbook
   currently has neither that file nor an output; its GPU is not assumed.
5. Review `git diff`, run `nix flake check`, and plan a temporary `nh os test`
   for the selected host. Permanent activation and bootloader changes require
   explicit approval; see [installation](installation-laptop.md) and
   [bootloader precautions](dual-boot-windows.md#grub-with-os-prober-alternative).

## Ownership and smoke checks

NixOS owns `/etc/xdg/hypr/host.lua`, not a global `hyprland.lua` or
`dms-base.lua`. `modules/nixos/desktop/hyprland-base.lua` contains only six
literal imports: `dms.colors`, `dms.layout`, `dms.outputs`, `dms.cursor`,
`dms.windowrules`, and `dms.binds`. Nix embeds them with `builtins.readFile` in
both the shared main template and HM's personal main, not a runtime loader.
Both use `require("/etc/xdg/hypr/host")` once, without extension or `dofile`,
after the DMS imports and, for HM, personal preferences.

NixOS installs `dms-hyprland-init` through `environment.systemPackages`.
UWSM's `wayland-wm@` template runs it as the user in `ExecStartPre`, after
preparing the environment, only when `XDG_CURRENT_DESKTOP` identifies Hyprland.
Before the compositor or DMS starts, it copies pinned DMS defaults into missing
`$XDG_CONFIG_HOME/hypr/dms/*.lua` files (default `~/.config/hypr/dms/`), private
and writable, and copies the shared main template only if the personal main is
absent. Existing files and symlinks are never replaced, including empty files,
dangling links, and malformed Lua. It adds no `binds-user.lua`. If legacy
`hyprland.conf` exists without a Lua main, it does nothing, avoiding Lua's
precedence over legacy configuration.

This creates new user files; it does not promise zero HOME writes or repair
invalid existing configuration. `dms setup headless --skip-existing` does not
fill partial profiles, hence this minimal seed. Normal UWSM sessions need no
manual setup; outside UWSM, run `dms-hyprland-init` explicitly if needed.

DMS/chezmoi keep ownership of their existing user files, scripts, and secret
templates; do not declare the same paths in HM or NixOS. HM owns only its
selected personal configuration, including plugin code under
`~/.config/DankMaterialShell/plugins/` and the GPG agent's user service.
Plugins use the official DMS Home Manager module and plugin registry, selected
through `programs.dank-material-shell.plugins.<name>.enable`. The DMS input is
pinned to v1.6.2 to match the current host package; review both when upgrading.
HM reuses NixOS's patched DMS and Quickshell packages, leaves shell startup to
NixOS (`systemd.enable = false`), and does not manage personal settings
(`managePluginSettings = false`). Update Nix-managed plugin code through Nix,
not DMS's plugin updater. DMS still owns plugin settings/state.

When migrating existing plugins, preserve their directories and symlinks in a
backup outside the plugin directory before letting HM take ownership. HM's
`.bak` mechanism does not back up foreign symlinks, and DMS can discover plugin
backups left inside its watched directory. Do not force-overwrite existing
plugins or delete their backups.

Mikel's `~/.gnupg/gpg-agent.conf` and `sshcontrol` remain
chezmoi-owned and untouched; HM disables management of the former and selects
pinentry explicitly in the GPG agent service's `ExecStart`. Tunnel Agent's
desktop entry uses the absolute FHS wrapper path; host-specific scaling lives
in `home.sessionVariables.AVALONIA_SCREEN_SCALE_FACTORS`.
Desktop sets DankGreeter's `configHome` to `config.users.users.mikel.home`.
The native nixpkgs `preStart` imports Mikel's DMS settings, colors, custom theme
and referenced wallpapers into `/var/lib/dms-greeter` when greetd starts.
This is one common login appearance for all accounts, not per-user profiles or
live synchronization. DMS/chezmoi retain ownership of the source files; no
exporter, watcher, timer or additional HOME permissions are introduced.

The shared module keeps nixpkgs' default `configHome = null`. With no
`configHome` or `configFiles` sources, we disable nixpkgs' appearance-sync
`preStart`: the pinned implementation otherwise copies cached themes or
wallpapers onto themselves and aborts greetd. Tmpfiles still provisions the
cache directory. In cache-only mode existing files must already be prepared and
readable by `dms-greeter`; this does not rename manually added color files or
repair their permissions. Explicit sync sources retain the upstream hook,
including its current limitations if a source goes missing. Review this
workaround when upgrading nixpkgs. Do not restart greetd in an active session
just to refresh appearance.

See official [NixOS configuration](https://danklinux.com/docs/dankgreeter/nixos)
and [greeter cache format](https://danklinux.com/docs/dankgreeter/configuration).
Do not delete the cache to work around startup errors. UWSM starts DMS through
`graphical-session.target`; do not also run `dms run` from Hyprland Lua.

`nix flake check` includes [tests/default.nix](../tests/default.nix) for base
evaluation without HM, two-user isolation, no implicit NVIDIA, separation of
system capabilities and personal apps/gaming, and Gamescope's use of the user's
Steam and the system wrapper. Its `greeter-cache` check covers an empty cache,
repeated preparation with cached theme/wallpapers, unchanged file contents,
and preservation of explicit sync opt-ins. It also exercises the desktop's
native import against disposable HOME/cache fixtures, including updated theme
and wallpaper sources without modifying the originals.
[tests/dms-session.sh](../tests/dms-session.sh)
uses the real DMS CLI (`config resolve-include` and `keybinds`) for fresh and
HM-plus-partial profiles, and real `Hyprland --verify-config` without starting
a compositor. It checks empty/malformed files, dangling links, legacy profiles,
custom/default XDG paths, non-Hyprland gating, and idempotence.

These checks use disposable profiles, not the real HOME, and do not activate
the system. Parser/CLI checks do not verify login, GPU behavior, or live DMS
watchers.

After an approved temporary activation, manually check:

- Fresh user without HM: DankGreeter's `Hyprland (uwsm-managed)` session starts;
  DMS, terminal, launcher, monitor layout, audio, portals, and locking work.
- Partial DMS profile: existing fragments remain unchanged; initialization adds
  missing defaults as writable user files. Check live DMS edits/watchers. Use a
  disposable account for malformed-Lua checks; never damage a real profile.
- Mikel: preferences and plugins remain available; host display rules still
  apply. Steam sees Proton-GE and the Gamescope session launches his Steam.
- User without gaming: no inherited Steam/browser/plugin package selection or
  privileged groups; choosing the Steam session reports missing Steam.

See [nh operations](maintenance/nh.md) and [recovery](maintenance/recovery.md)
for activation and rollback procedures. No activation is implied by these docs.
