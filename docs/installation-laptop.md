# Laptop installation (`zenbook`)

Prepare this repository for machine-level host `zenbook`. It has no generated
hardware file or flake output yet, so it cannot currently be built. Generate
hardware data on that laptop; never copy `hosts/desktop/hardware-configuration.nix`.

## Generate unique hardware configuration

Generate this file on the Zenbook. Never copy `hosts/desktop/hardware-configuration.nix`.

If NixOS is already installed and booted:

```bash
cp /etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

If using the NixOS installer before the first configuration:

```bash
sudo nixos-generate-config --root /mnt
sudo install -D -m 0644 \
  /mnt/etc/nixos/hardware-configuration.nix \
  hosts/zenbook/hardware-configuration.nix
test -s hosts/zenbook/hardware-configuration.nix
```

The generated file contains this laptop's filesystems, boot devices, kernel modules, and UUIDs. Review encrypted-root and swap settings for the actual machine. The Zenbook profile enables zswap, which requires persistent swap declared by this generated hardware file. If hibernation is required, configure real persistent encrypted swap and matching resume settings; zswap alone cannot provide hibernation storage.

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

Do not add `nixosConfigurations.zenbook` to `flake.nix` until `hosts/zenbook/hardware-configuration.nix` exists and belongs to this Zenbook.

## Add host and validate

After the hardware file exists, add a `zenbook` output beside `desktop` in `flake.nix`, using the existing `hosts/zenbook` module:

```nix
nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [ ./hosts/zenbook ];
};
```

Review GPU drivers, bootloader, hostname, state version, and optional services
for this machine using the [host checklist](architecture.md#new-host-checklist).
NVIDIA and gaming are not inherited from desktop. Then validate and test the
machine-level target:

```bash
nix flake check
git diff
nh os test . -H zenbook
```

`test` is temporary and does not change the boot default. Confirm networking, audio, Bluetooth, Hyprland, DankGreeter, DMS, keyboard layout, locking, notifications, and Wayland portals before applying the generation.

## Switch only after testing

Review the diff, especially the generated hardware file, before switching:

```bash
git diff --stat
git diff
nh os switch . -H zenbook
```

Do not copy desktop hardware or run `switch` before `nix flake check` and the temporary test succeed. Permanent activation requires explicit approval. The Zenbook profile uses a Spanish keyboard by default; `Alt+Shift` switches to US International for an external US keyboard.
