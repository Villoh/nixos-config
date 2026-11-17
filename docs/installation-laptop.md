# Laptop installation (`zenbook`)

Install this repository's `zenbook` host on the Zenbook. The host is fully written
(`hosts/zenbook/`), but it needs two things that only exist on the laptop itself: its
generated hardware file, and the flake output, which is prepared as a comment in
`flake.nix` and cannot be enabled before that file exists. Until then it cannot be built.
Never copy `hosts/desktop/hardware-configuration.nix`.

The laptop is used in two modes, and the configuration handles both without a rebuild:

- **Docked**: the desktop's two monitors (ASUS VG259QM, Acer VG280K), through the eGPU or
  any port. The internal panel is switched off.
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
  DankGreeter), power-profiles-daemon and UPower (battery in the shell);
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
edit the `ASUS` and `ACER` strings there (`hyprctl monitors` shows each `description`).

| Situation | Internal panel `eDP-1` |
| --- | --- |
| A desk monitor is connected | off |
| Lid closed with any other monitor connected (clamshell) | off |
| Another monitor (work), lid open | on: the laptop is a second screen |
| Laptop alone | on |
| Lid closed, no monitor | on, but logind suspends the machine |

- Layout, scale and workspace pinning are the desktop's: ASUS on the left, Acer on the right,
  bottoms aligned; workspace 1 on the ASUS and 6 on the Acer. Without those monitors the rules
  match nothing.
- The panel state is recomputed in one function (`sync_panel`) on start, on monitor
  hot-plug and on lid events, with a 500 ms debounce. Turning the panel back on runs
  `hyprctl reload`, because `hl.monitor` cannot enable an output when no monitor is active.
- The lid is read from `/proc/acpi/button/lid/*/state`, not from the bind callback (which can
  report the old state in Hyprland 0.57.2). If that file is missing the lid counts as open and
  only the desk rule works.
- `xwayland.force_zero_scaling = true` and `render.cm_auto_hdr = 0` are the same as desktop's
  (mixed-DPI XWayland apps handle their own scale; no auto HDR for fullscreen Electron apps).
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

## 7. Validate and test

```bash
nix flake check
git diff
nh os test . -H zenbook
```

`test` is temporary and does not change the boot default.

## 8. Checks after the temporary test

General: networking, audio, Bluetooth, Hyprland, DankGreeter, DMS, keyboard layout, locking,
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
  (`AVALONIA_SCREEN_SCALE_FACTORS`, `xrandr --primary`, the greeter's cursor monitor) are not
  copied to Zenbook because the names depend on the port; add them only if needed.

### Work monitor

- Lid open: the panel stays on beside the other monitor. Lid closed: the panel turns off.

### eGPU

Follow the notes above; nothing about it is verified.

## 9. Switch only after testing

Review the diff, especially the generated hardware file, before switching:

```bash
git diff --stat
git diff
nh os switch . -H zenbook
```

Do not copy desktop hardware or run `switch` before `nix flake check` and the temporary test succeed. Permanent activation requires explicit approval. The Zenbook profile uses a Spanish keyboard by default; `Alt+Shift` switches to US International for an external US keyboard.

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
