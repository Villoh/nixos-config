# Laptop installation (`zenbook`)

Install this repository's `zenbook` host on the Zenbook. The host is fully written
(`hosts/zenbook/`), but it needs two things that only exist on the laptop itself: its
generated hardware file, and the flake output, which is prepared as a comment in
`flake.nix` and cannot be enabled before that file exists. Until then it cannot be built.
Never copy `hosts/desktop/hardware-configuration.nix`.

The laptop is used in two modes, and the configuration handles both without a rebuild:

- **Docked**: the desktop's two monitors (TCL 27C2A, Acer VG280K), through the eGPU or
  any port. The internal panel stays on with the lid open and goes off with the lid closed.
- **Undocked**: the laptop alone. The internal panel is on.

See [Docked and undocked](#docked-and-undocked) for the rules.

## Before you start

Have at hand:

- The **VeraCrypt-encrypted external disk** and the **USB with its keyfiles** (the volume
  needs the password plus the keyfiles). The disk holds everything this guide needs under
  `Computers/`:
  - `Keys/gpg/gpg-private-key.asc` and `Keys/gpg/gpg-ownertrust.txt`: the GPG backup.
  - `Keys/ssh/id_personal.pub` and `id_work.pub`: the public SSH keys.
  - `NixOS-Zenbook/`: this guide and the agent/SSH configuration files
    (`gpg-agent.conf`, `sshcontrol`, `ssh-config`).
- A network connection.

Why the key comes first: `flake.nix` has a private input over SSH
(`git+ssh://git@github.com/Villoh/nix-ttf-ms-win11-auto`; anonymous access returns 404), so
the first evaluation needs SSH. SSH authenticates with the GPG authentication subkey served
by `gpg-agent`; there is no private SSH key file. This repository and the dotfiles are
public, so they can be cloned over HTTPS.

The agent and SSH configuration files are chezmoi's (`private_dot_gnupg/` and `dot_ssh/` in
the dotfiles repository); the copies on the disk are a snapshot of them, so the first login
does not depend on the network or on chezmoi. This configuration never manages them.

Partitions, LUKS and swap are decided when installing NixOS, not by this repository. The
Zenbook profile enables zswap, which needs persistent swap (see step 4).

## 1. Install NixOS

Install NixOS from the installer with the layout you want (encrypted root, persistent swap),
create your user (in `wheel`, so it has `sudo`), and boot into it. The rest of the guide runs
on that minimal system, from a TTY or a terminal, as your normal user.

The latest installer ISO is NixOS 26.05 (systemd 260), while the flake follows `nixos-unstable`
(26.11, systemd 261 or later). That mismatch breaks the first activation with some `nh`
versions: see [First activation](#first-activation-from-the-installer-system) in step 7. A
26.11 or unstable ISO avoids it.

## 2. Bootstrap tools, GPG key and SSH

A minimal install has neither flakes, `nh`, nor your tools. Open one shell with everything
and keep using **that same shell** until the end (it holds the SSH agent variables).
VeraCrypt is unfree, hence the extra variable:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
export NIXPKGS_ALLOW_UNFREE=1
nix shell --impure nixpkgs#git nixpkgs#nh nixpkgs#gnupg nixpkgs#pinentry-curses \
  nixpkgs#chezmoi nixpkgs#veracrypt
```

`nh` and `veracrypt` are installed by the configuration afterwards (`programs.nh.enable`,
`modules/home/security/packages.nix`); this shell is only needed until the first switch.

### Mount the external disk

The volume opens with a **password plus keyfiles**, and the keyfiles are on a **separate USB**.
Plug in both. Mount the keyfile USB read-only first:

```bash
lsblk -f                                   # find both devices, e.g. /dev/sda1 and /dev/sdb1
sudo mkdir -p /mnt/usb /mnt/keys
sudo mount -o ro /dev/sdY1 /mnt/usb        # keyfile USB (use its real filesystem; it is not encrypted)
sudo "$(command -v veracrypt)" --text \
  --keyfiles=/mnt/usb/<keyfile> --pim=0 --protect-hidden=no \
  --mount /dev/sdX1 /mnt/keys              # VeraCrypt disk
```

It asks only for the password; the keyfiles, PIM and hidden-volume protection come from the
options, so nothing else is prompted. `--keyfiles` takes a comma-separated list of files, or a
directory (every file in it is used). Do not pass `--password`, which would leave it in the
shell history. If the volume has a custom PIM, replace `--pim=0` with it. The volume holds an
NTFS filesystem, which the kernel's `ntfs3` driver reads. Option names are checked against the
installed `veracrypt --help`; the mount itself is untested on the minimal system. If it
complains about device-mapper or FUSE, load the modules (`sudo modprobe dm_crypt fuse`) and
retry.

Unmount the keyfile USB as soon as the volume is open, so it can be removed:

```bash
sudo umount /mnt/usb
```

### Seed GPG and SSH from the disk

Copy the agent and SSH files from the disk. These are the same five files as the dotfiles
bootstrap guide copies, so chezmoi shows no diff for them later:

```bash
d=/mnt/keys/Computers
mkdir -p "$HOME/.gnupg" "$HOME/.ssh"
cp "$d/NixOS-Zenbook/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
cp "$d/NixOS-Zenbook/sshcontrol" "$HOME/.gnupg/sshcontrol"
cp "$d/NixOS-Zenbook/ssh-config" "$HOME/.ssh/config"
cp "$d/Keys/ssh/id_personal.pub" "$d/Keys/ssh/id_work.pub" "$HOME/.ssh/"
chmod 700 "$HOME/.gnupg" "$HOME/.ssh"
chmod 600 "$HOME/.gnupg/gpg-agent.conf" "$HOME/.gnupg/sshcontrol" "$HOME/.ssh/config"
chmod 644 "$HOME/.ssh/"*.pub
```

### Start the agent

Start the agent **before importing the key**: the import asks for the key's passphrase, and
without a terminal pinentry it fails. Home Manager's `gpg-agent` service does not exist yet,
so start it by hand with `pinentry-curses` (the service later uses the graphical one).
`GPG_TTY` is required, or pinentry cannot find the terminal ("Inappropriate ioctl for
device"). `enable-ssh-support` comes from the copied `gpg-agent.conf`:

```bash
export GPG_TTY="$(tty)"
gpgconf --kill gpg-agent
gpg-agent --daemon --pinentry-program "$(command -v pinentry-curses)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
```

### Import the private GPG key

```bash
gpg --import /mnt/keys/Computers/Keys/gpg/gpg-private-key.asc
gpg --import-ownertrust /mnt/keys/Computers/Keys/gpg/gpg-ownertrust.txt
gpg --list-secret-keys --keyid-format long 2E5BD225E500AB50   # the dotfiles' recipient key
```

Now dismount the disk. Never copy the exported key anywhere else, and never into a repository:

```bash
sudo "$(command -v veracrypt)" --text --dismount /mnt/keys
```

### Test SSH

```bash
ssh-add -L                 # lists the authentication key(s)
ssh -T git@github.com      # "Hi Villoh! You've successfully authenticated..."
```

Test `git@github.com` (not only `github-personal`): that is the host the flake input uses.
Run the build as your normal user in this shell. `sudo` drops `SSH_AUTH_SOCK`, and Nix fetches
`git+ssh` inputs from the evaluating user, not from the daemon.

## 3. Get the repository

```bash
git clone git@github.com:Villoh/nixos-config.git
cd nixos-config
```

Git has no identity yet, and it does not need one: cloning, `git add` and building do not use
it. Do not commit until step 10. The identity and signing settings are encrypted in the
dotfiles (`~/.config/git/local` and `work`) and `chezmoi apply` creates them; do not configure
git by hand.

## 4. Generate the hardware configuration

Generate this file on the Zenbook. Never copy `hosts/desktop/hardware-configuration.nix`.

If NixOS is already installed and booted:

```bash
cp /etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

If you are still in the installer, before the first configuration:

```bash
sudo nixos-generate-config --root /mnt
sudo install -D -m 0644 \
  /mnt/etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

The generated file contains this laptop's filesystems, boot devices, kernel modules, and UUIDs. Review encrypted-root and swap settings for the actual machine. The Zenbook profile enables zswap, which requires persistent swap declared by this generated hardware file. If hibernation is required, configure real persistent encrypted swap and matching resume settings; zswap alone cannot provide hibernation storage.

Flakes only see files tracked by Git, so add it before evaluating:

```bash
git add hosts/zenbook/hardware-configuration.nix
```

## 5. Enable the flake output

In `flake.nix`, uncomment the prepared block beside `desktop`:

```nix
nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [ ./hosts/zenbook ];
};
```

Do not enable it before `hosts/zenbook/hardware-configuration.nix` exists and belongs to this
Zenbook: an output that cannot evaluate breaks `nix flake check` for every host.

## 6. Review the host

`hosts/zenbook/default.nix` selects:

- hostname `nixos-zenbook`, state version `26.05`, `systemd-boot` (no Secure Boot, no
  Lanzaboote, no Acid Boot: those are desktop-only);
- the `laptop` profile: audio, Bluetooth, zswap, the desktop session (Hyprland, DMS,
  Dux Greeter), power-profiles-daemon and UPower (battery in the shell);
- Intel `thermald`, the NVIDIA eGPU module (see below), and the optional services Docker,
  Flatpak, printing, Tailscale and KDE Connect;
- user `mikel` with Home Manager, plus the Dux Greeter appearance synced from his home. On a
  fresh home the missing files are skipped and the greeter keeps its defaults.

NVIDIA and gaming are not inherited from desktop: there is no `profiles/gaming.nix` and no
`modules/home/gaming` import here. Add them deliberately if you want games on the eGPU. Check
the [host checklist](architecture.md#new-host-checklist) for anything else machine-specific.

## Docked and undocked

`hosts/zenbook/display.nix` writes the shared Hyprland rules to `/etc/xdg/hypr/host.lua`,
which the session and the greeter both load. Desk monitors are matched by EDID description
(`desc:`), so the layout follows them through any port, dock or eGPU. To change the monitors,
edit the `TCL` and `ACER` strings there (`hyprctl monitors` shows each `description`).

| Situation | Internal panel `eDP-1` |
| --- | --- |
| A desk monitor is connected, lid open | on: workspace 11, and a lifeline if the eGPU crashes |
| Lid closed with any other monitor connected (clamshell) | off |
| Another monitor (work), lid open | on: the laptop is a second screen |
| Laptop alone | on |
| Lid closed, no monitor | on, but logind suspends the machine |

- Layout, scale and workspace pinning are the desktop's: TCL on the left, Acer on the right,
  both 4K at scale 1.5; workspaces 1-5 on the TCL and 6-10 on the Acer. Without those monitors,
  1-5 go to the panel `eDP-1` and 6-10 to the first other monitor (or the panel when alone),
  so an unknown display gets 6-10 instead of Hyprland's 11, 12... In clamshell (panel off) all
  ten go to the other monitor.
- Workspaces per situation (the "Layout" bullet above, as a table). `(?)` marks cases not
  checked on the hardware:

  | Situation | TCL | Acer | Other monitor | Panel `eDP-1` | Focus |
  | --- | --- | --- | --- | --- | --- |
  | Laptop alone, lid open | - | - | - | 1-10, only 1 persistent (6 and 11 are not, so no extra empty workspaces) | panel, workspace 1 |
  | Laptop alone, lid closed | - | - | - | logind suspends | - |
  | Desk (TCL + Acer), lid open | 1-5 | 6-10 | - | 11 (persistent) | TCL, workspace 1 |
  | Desk, lid closed | 1-5 | 6-10 | - | off; its workspace and windows move to the first monitor in Hyprland's list, the Acer in the test | TCL |
  | TCL only, lid open | 1-5 | - | - | 11; 6-10 open on the focused monitor (?) | TCL |
  | Acer only, lid open | 1-5 open on the focused monitor (?) | 6-10 | - | 11 | Acer |
  | Other monitor, lid open | - | - | 6-10 | 1-5 | panel |
  | Other monitor, lid closed | - | - | 1-10 | off | that monitor |

- Where the panel's workspace goes when it turns off was tested on 2026-11-20 by disabling
  `eDP-1` with a window on workspace 12: workspace and window moved to monitor ID 0 (the
  Acer), not to the focused monitor (the TCL). The order follows Hyprland's monitor IDs,
  which depend on connection order, so it is not fixed. Seen once.
- Closing the lid with a monitor connected does not suspend: logind has
  `HandleLidSwitch=suspend` but `HandleLidSwitchDocked=ignore` (checked with
  `busctl get-property org.freedesktop.login1 ... Docked`, which was `true`). Hyprland turns
  the panel off instead (clamshell). The machine suspends only with no external monitor.
- At login the panel is the only monitor, so workspace 1 and the apps opened on it are
  created there, and Hyprland's rules do not move an existing workspace: the TCL would get
  11. `rehome()` in `display.lua` moves workspaces 1-11 to their desk monitor after each
  recompute; an absent monitor leaves its workspaces where they are. Checked live only for
  the no-op case; the login case needs a boot to see.
- Known gap: plugging a desk monitor in with the session open did not update the workspace
  rules (seen on 2026-11-20 with the Acer on HDMI: the rules stayed on `eDP-1` until
  `hyprctl reload`). Plug monitors in before logging in, or run `hyprctl reload`.
- The panel state is recomputed in one function (`sync_panel`) on start, on monitor
  hot-plug and on lid events, with a 500 ms debounce. Turning the panel back on runs
  `hyprctl reload`, because `hl.monitor` cannot enable an output when no monitor is active.
- The lid is read from `/proc/acpi/button/lid/*/state`, not from the bind callback (which can
  report the old state in Hyprland 0.57.2). If that file is missing the lid counts as open and
  only the desk rule works.
- `xwayland.force_zero_scaling = true` and `render.cm_auto_hdr = 1` are the same as desktop's
  (mixed-DPI XWayland apps handle their own scale; HDR only for fullscreen HDR content).
  `force_zero_scaling` also applies with the panel alone.

## NVIDIA eGPU

The Zenbook (Core Ultra 9 285H, Intel iGPU) is prepared to use the desktop's RTX 3080 in a
Thunderbolt enclosure through `modules/nixos/hardware/egpu-nvidia.nix`. The iGPU renders the
desktop when the eGPU is absent. It has not been tested on this hardware.
The eGPU is meant for monitors, games and LLMs, so it is Hyprland's primary renderer when attached.

- Enrol the enclosure once: `boltctl list`, then `boltctl enroll <uuid>`.
- `/dev/dri/igpu` and `/dev/dri/egpu` are udev aliases matched by vendor and class, so no bus
  ID is needed. `AQ_DRM_DEVICES=egpu:igpu` in `/etc/xdg/uwsm/env-hyprland` makes the first
  available card the primary renderer: the eGPU if it is attached when you log in, otherwise
  the iGPU. Attach it before logging in; attaching it later is untested.
- Hyprland's primary GPU does not decide where a game renders: Vulkan and GL choose their
  own device. If the eGPU is attached at login, `env-hyprland` exports the NVIDIA offload
  variables for the whole session, so games and other programs need no wrapper. Without the
  eGPU nothing is set. `nvidia-offload <program>` covers a card attached after login. A NixOS
  user with a Wayland eGPU used the same variables session-wide, plus `MESA_VK_DEVICE_SELECT`
  (discourse.nixos.org, Dec 2025, KDE); this is not tested on this hardware.
- Monitors wired to the eGPU only work if that card is in `AQ_DRM_DEVICES`. Hyprland's
  Nvidia wiki warns that multi-GPU with monitors on an NVIDIA card can be broken or slow, and
  lists two things to try: change the primary GPU (swap the order) and
  `AQ_FORCE_LINEAR_BLIT=0` (commented out in the module). Neither is measured here.
- LLMs and other compute need no display stack, and the Arch wiki says compute-only use
  supports hotplug; do not enable `nvidia-persistenced`, which it says prevents a clean
  hot-unplug. Stop the workload before unplugging.
- Do not hot-unplug the eGPU during a Hyprland session. Aquamarine supports GPU hotplug only
  for a non-primary GPU, and here the eGPU is primary. With the proprietary NVIDIA driver and
  modesetting on, Hyprland keeps `/dev/nvidia0` open and the card cannot be released;
  unplugging an eGPU that has a monitor attached crashes Hyprland (forum report, 2025); an
  NVIDIA driver discussion (open-gpu-kernel-modules #1190) describes the desktop hanging on
  surprise removal. Log out first. Untested on this hardware.
- Do not set `__EGL_VENDOR_LIBRARY_FILENAMES` to Mesa globally to keep NVIDIA out of the
  compositor: the Arch wiki suggests it for hotplug, but the Omarchy hybrid-GPU notes say it
  breaks Hyprland's own EGL start-up.
- Performance: Thunderbolt limits host-to-eGPU bandwidth (Arch wiki), and one OCuLink vs
  Thunderbolt test (rkblog, AMD card) saw a large drop on Thunderbolt. For games, OCuLink is
  the stronger lever. That same test scored better on the laptop's own screen than on a
  monitor attached to the eGPU, so test both before assuming otherwise.
- If the card is not seen at boot, the Arch wiki says some systems need the `thunderbolt`
  module loaded before `nvidia_drm` (early/initrd), and some need `pcie_ports=native` and
  `pci=assign-busses,hpbussize=0x33,realloc,hpmmiosize=128M,hpmmioprefsize=16G`. Neither is
  set here; add only if needed. A NixOS thread also reports that a late-plugged second NVIDIA
  GPU only appeared after running `nvidia-smi` as root (device nodes), another reason to
  attach the card before boot.
- `bolt` is harmless with OCuLink: `boltd` starts from a udev rule only when a Thunderbolt
  device appears. OCuLink needs no enrolment, so only this note changes.
- Check the S3 resume fix from `nvidia.nix` (VRAM preservation) with the eGPU attached.

## 7. Build and first activation

### Binary caches before the first build

`modules/nixos/core/nix.nix` trusts three Cachix caches (`sonora`, `kopuz`, `handy-computer`), so
their packages are downloaded instead of compiled. That file only applies **after** this
configuration is active, so the first build, on the installer's system, would use only
`cache.nixos.org`. A dry run of the `zenbook` build against an empty store counted 5035
derivations to build without them and 969 with them, for about 12 GiB to download either way.
Compiling `kopuz` alone is about 2200 derivations.

Put them in the installer's own configuration first. Keep the values identical to
`modules/nixos/core/nix.nix` (that file is the source of truth). Add to `/etc/nixos/configuration.nix`:

```nix
nix.settings = {
  extra-substituters = [
    "https://sonora.cachix.org"
    "https://kopuz.cachix.org"
    "https://handy-computer.cachix.org"
  ];
  extra-trusted-public-keys = [
    "sonora.cachix.org-1:qbPeDsvZPbwUWHpQS5Oe0bjz5oHAVscHem+MCzwrc9Q="
    "kopuz.cachix.org-1:J2X3AnAYhKTJW5S3aCLoA1ckonQXVNZMQvhZA0YAufw="
    "handy-computer.cachix.org-1:Sihzctn6DC0CJM5QeL+9nBEL3CL8c33m777C+eIv748="
  ];
};
```

Then `sudo nixos-rebuild switch` (the installer's own configuration, no flake) and check
`nix config show extra-substituters`. Settings in the daemon's configuration apply to every user,
so `trusted-users` is not needed.

There is a command-line form, `--option extra-substituters ... --option extra-trusted-public-keys ...`,
but Nix only honours it for trusted users. A normal user gets `warning: ignoring the client-specified
setting ..., because it is a restricted setting and you are not a trusted user`, and the same
restriction applies to `~/.config/nix/nix.conf` and to a flake's `nixConfig`. Running the build with
`sudo` would work, but then root fetches the private `git+ssh` input and needs its own SSH agent
access and `known_hosts`. Editing `/etc/nixos/configuration.nix` is the simplest.

In that dry run, with the caches `kopuz` and `handy` no longer appear among the derivations to
build, but some of `sonora` still does (`sonora-deps`, `sonora-alsa-plugins`, a git crate), so its
cache does not seem to cover all of it. It is an estimate, not a measurement.

### Build

```bash
nix flake check
git diff
nh os build . -H zenbook
```

Expect a long first build: about 12 GiB to download plus some local compilation (NVIDIA, `sonora`,
`xwayland`, `dux-shell`, the Windows fonts, which are extracted in a VM). Stopping it with `Ctrl-C`
is safe: finished derivations stay in the store and the next run resumes.

### First activation from the installer system

After the build, activate the configuration temporarily with `nh os test . -H zenbook`. Observed
on the laptop: from the installer's system it builds everything and then fails with

```text
systemd-run: unrecognized option '--output=cat'
Error: Activating configuration (exit status ExitStatus(Exited(1)))
```

Since version 4.5.0, `nh` activates the configuration through `systemd-run --output=cat`, an
option that exists from systemd 261. The installer's system has 260. This only affects the first
activation: once the new generation is running, `nh` works. The fix is in `nh`'s `master`
(it checks the `systemd-run` version and falls back to `--pipe`), but at the time of writing it
is not in a release. `nixos-rebuild` already has the equivalent fix
([nixpkgs #569087](https://github.com/NixOS/nixpkgs/pull/569087)).

Check `nh --version`. The `nh` in this repository's lock is 4.4.2, which according to its changelog
does not activate through `systemd-run`; the one from `nix shell nixpkgs#nh` can be newer. If it is 4.5.0, use one of these from a
**TTY** (`Ctrl+Alt+F3`), not from the graphical session: without `systemd-run` the activation runs
inside your session, and restarting the display manager would close it.

```bash
# Option A: tell nh not to use systemd-run (documented in nh's changelog; untested here)
NH_NO_SYSTEMD_RUN=1 nh os test . -H zenbook

# Option B: activate the build directly
nh os build . -H zenbook                          # nothing to compile if it already finished; creates ./result
sudo ./result/bin/switch-to-configuration test
```

Neither workaround has been confirmed on this hardware yet. `test` is temporary and does not
change the boot default; rebooting returns to the previous system.

## 8. Checks after the temporary test

General: networking, audio, Bluetooth, Hyprland, Dux Greeter, DMS, keyboard layout, locking,
notifications and Wayland portals. Then the laptop-specific ones. None of these has been run on
the hardware yet:

### Undocked

- `hyprctl monitors all`: the panel is called `eDP-1` (`display.nix` hard-codes that name).
  If it is not, change it there.
- The UI scale is right and X11 apps are not tiny. If they are, `force_zero_scaling` is the
  cause; set it only while docked (changing it at runtime is untested).
- `ls /proc/acpi/button/lid/`: a `LID0`, `LID` or `LID1` directory exists.
- Closing the lid with nothing attached suspends and resumes.
- The battery shows in DMS (UPower), `powerprofilesctl` works, and
  `systemctl status thermald` is active.

### Docked

Attach the eGPU and monitors *before* logging in.

- Layout, scales (1 and 1.5) and workspaces 1 and 6 match the desktop.
- `eDP-1` is off. Unplugging the monitors brings the panel back; if it stays off, run
  `hyprctl reload`, and report it: the fallback is a `systemd --user` service that watches the
  lid and calls `hyprctl eval`.
- The lid binds work. Reports say `switch:*` binds may stop working when they sit in the same
  Lua file as the `hl.monitor` rules, which is the case here. Test closing and opening the lid.
- Note the connector names (`hyprctl monitors`, `xrandr`). Desktop's `DP-1`/`HDMI-A-1` values
  (`xrandr --primary`, the greeter's cursor monitor) are not copied to Zenbook because the names
  depend on the port; add them only if needed. `AVALONIA_SCREEN_SCALE_FACTORS` is set in
  `hosts/zenbook/default.nix` with the current names (`eDP-1`, `HDMI-A-2`, `DP-3`): update them
  if a monitor changes port.

### Work monitor

- Lid open: the panel stays on beside the other monitor. Lid closed: the panel turns off.

### Touchscreen

Gestures come from the hyprgrass plugin: `hosts/zenbook/touchscreen.nix` loads it and
`modules/home/desktop/hyprland/touchscreen.nix` lists the gestures (also in the DMS keybind
viewer, under "Touch"). None is tested yet.

- `hyprctl plugin list` shows `hyprgrass`. If not, the plugin does not match the running
  Hyprland: see [updates](maintenance/updates.md#own-packages-packages).
- 3 fingers: swipe left/right switches workspace, up is the overview, down the scratchpad.
  4 fingers: swipe left/right cycles windows, up is fullscreen, down toggles floating.
  5 fingers: swipe left/right sends the window to another workspace, up pops it out, down
  closes it.
- Hold 3 fingers and drag moves the window; hold 4 and drag resizes it.
- Swipes from the edges: bottom opens the launcher, top the Control Center, left the
  overview, right the notifications. Sliding along the right edge changes the volume and
  along the left edge the brightness.
- If an edge swipe also hits the bar or an app's own edge, raise `edge_margin` or lower it
  in `hosts/zenbook/touchscreen.nix`.

### eGPU

Follow the notes above; nothing about it is verified.

## 9. Switch only after testing

Review the diff, especially the generated hardware file, before switching:

```bash
git diff --stat
git diff
nh os switch . -H zenbook
```

If the `nh` activation error above comes back (the running systemd is still the old one), use the
same workaround, but with `boot` or `switch`: `sudo ./result/bin/switch-to-configuration boot`.
After a successful `test` the running systemd is normally already the new one, so `nh os switch`
should work; this is not confirmed.

Do not copy desktop hardware or run `switch` before `nix flake check` and the temporary test succeed. Permanent activation requires explicit approval. The Zenbook profile uses a Spanish keyboard; the external AL68 keyboard is pinned to US International.

## 10. After the first switch

1. Stop the agent started by hand, so Home Manager's `gpg-agent` service (graphical pinentry)
   takes over, then log out and back in:

   ```bash
   gpgconf --kill gpg-agent
   ```

2. Apply the dotfiles. `chezmoi diff` must be readable first; a decryption error means the
   private key or the agent is not ready (see the dotfiles bootstrap guide). The five files
   copied from the disk in step 2 should match chezmoi's; if the disk snapshot is stale,
   the diff shows it.

   ```bash
   chezmoi init https://github.com/Villoh/dotfiles
   chezmoi diff
   chezmoi apply
   ```

3. Commit the new hardware file and the enabled flake output.
4. Remove the exported key from anywhere it was copied; it should only live on the encrypted disk.

## Recovery

If something fails, select an earlier generation from the boot menu and fix the checkout from a
TTY. See [Maintenance: recovery](maintenance/recovery.md).
