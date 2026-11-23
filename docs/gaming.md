# Gaming

Gaming is split in two so that a host can offer support without every user getting
a launcher.

| Layer | Where | What it provides |
| --- | --- | --- |
| Host support | `profiles/gaming.nix` → `modules/nixos/gaming/` | 32-bit graphics and audio, Steam controller udev rules, GameMode, Gamescope and the `Steam (user profile)` session |
| User clients | `modules/home/gaming/` | Steam, Proton-GE, Lutris, Heroic, Bottles, Wine/Winetricks, ProtonUp-Qt, ProtonPlus, MangoHud, GOverlay, Ludusavi |

Only `desktop` imports the profile, and only Mikel's Home Manager profile on that
host imports the user module (`hosts/desktop/default.nix`). The Zenbook and any
other user do not inherit it.

## Rules

- `programs.steam.enable` stays `false`: it would install a global Steam client.
  The NixOS module only supplies graphics libraries and fonts.
- The Home Manager module asserts that `hardware.steam-hardware` and 32-bit
  graphics are enabled on the host.
- GameMode is a host opt-in. Mikel's groups stay `wheel`, `networkmanager`,
  `docker` and `al68`; `gamemode` is not added.
- The `Steam (user profile)` session launches the logged-in user's own Steam
  through Gamescope and reports an error if that user has none installed.

## Proton and Wine versions

Proton-GE is declared in Nix and its Steam wrapper discovers it. Anything else
(Proton-CachyOS when available, Wine runners, per-launcher settings) is managed
from ProtonUp-Qt, ProtonPlus, Lutris or Heroic inside the user session. Those are
user settings and are not pinned in NixOS.

## HDR

Hyprland HDR (`render.cm_auto_hdr = 1`, fullscreen HDR content only) needs the game to
run on Wine's Wayland driver. Checked on 2026-11-22:

- **Proton Experimental does not work for HDR.** Neither the stable build
  (`experimental-11.0-20261112`) nor the `bleeding-edge` beta
  (`experimental-bleeding-edge-11.0-479548-20261122`) ships `winewayland`: only
  `winex11` is present, and their `proton` script has no `PROTON_ENABLE_WAYLAND` or HDR
  handling. The game runs through XWayland and reports "HDR is not detected".
- **Alternative: GE-Proton.** GE-Proton11-12 ships `winewayland` and detects HDR from the
  Wayland output. In Steam, force it under Properties → Compatibility, then launch with
  `PROTON_ENABLE_WAYLAND=1 PROTON_FORCE_HDR=1 %command%` in fullscreen. `PROTON_FORCE_HDR`
  is what makes Hyprland's `cm_auto_hdr` output look like HDR to Wine. Verified working
  with God of War on the TCL 27C2A.
- Use the monitor that runs 10-bit. The Acer VG280K is on HDMI 2.0 at 8-bit (see
  `hosts/zenbook/display.lua`), so HDR does not apply there.

The [Arch wiki HDR page](https://wiki.archlinux.org/title/HDR) agrees with this setup and
adds:

- **Vulkan HDR WSI:** NVIDIA 595.58.03 and later ship `VK_EXT_swapchain_colorspace` and
  `VK_EXT_hdr_metadata`, so the host's 595.112.07 needs neither the `vk-hdr-layer` package
  nor `ENABLE_HDR_WSI=1`. Older drivers do.
- **Flags:** its example sets `PROTON_ENABLE_HDR=1` (which sets `DXVK_HDR=1`). GE-Proton11-12's
  `proton` script says HDR detection no longer needs it; `PROTON_FORCE_HDR=1` is the flag
  that matters under Hyprland's `cm_auto_hdr`.
- **Other builds with the Wayland driver:** proton-cachyos with `PROTON_ENABLE_WAYLAND=1`
  and `DXVK_HDR=1`. Not installed here.
- **Gamescope is not a good fallback on NVIDIA.** The wiki warns that NVIDIA "is known to
  have critical issues" with Gamescope HDR, and Gamescope's HDR also needs the compositor to
  support the colour-management protocols. Not tested here.
- **Desktop HDR** needs `cm = "hdr"` and `bitdepth = 10` on the monitor. It is left off
  because it looked dim and washed out (see `hosts/zenbook/display.lua`); fullscreen HDR
  content switches automatically.
- **"HDR option missing although the display supports it"** can be a panel that keeps its
  HDR block in a DisplayID 2.0 extension. Not the case here: both monitors expose it in
  the CTA-861 block (PQ and HLG, BT.2020).

## Frame stalls on an NVIDIA eGPU

Periodic stalls of the game's render thread (CPU - Render 40-66 ms every ~10 s, also in
menus, GPU idle) came from `monitor-input watch` polling `ddcutil` every 10 s. DDC/CI goes
through the NVIDIA driver and holds its lock (`os_acquire_rwlock`), which blocks the game's
render and RHI threads. Stopping the watcher removed the stalls.

- `monitor-input` now reacts to DRM uevents only. The Acer raises a uevent when it leaves
  the PC's input; the TCL does not, so use `SUPER+CTRL+G` there.
- Other timer-driven GPU queries blocked the same threads: MangoHud's `gpu_stats` (its NVML
  thread) did, and `nvidia-smi dmon` very likely does. Leave `gpu_stats` out of
  `MANGOHUD_CONFIG` and measure with `frametime,fps` only.
- These ruled out as causes (no change when toggled): Proton Experimental vs GE-Proton,
  `VKD3D_CONFIG` options, DX11 vs DX12, Reflex/DLSS, CPU core pinning, ntsync vs fsync,
  Thunderbolt bandwidth, VRAM, temperature.

## ntsync

`boot.kernelModules = [ "ntsync" ]` (`modules/nixos/gaming/steam.nix`) creates `/dev/ntsync`.
Proton 11+ and GE-Proton use it when present and fall back to fsync otherwise. Check it is
in use with `ls -l /proc/$(pgrep -x GameThread | head -1)/fd | grep -c ntsync`: a non-zero
count means the game uses it. It did not change the stalls above.

## Zenbook

The Zenbook has no gaming profile. Add `profiles/gaming.nix` and
`modules/home/gaming` deliberately if games should run on the eGPU (see
[installation-laptop](installation-laptop.md#nvidia-egpu)).
