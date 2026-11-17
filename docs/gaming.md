# Gaming

Gaming is split in two so that a host can offer support without every user getting
a launcher.

| Layer | Where | What it provides |
| --- | --- | --- |
| Host support | `profiles/gaming.nix` → `modules/nixos/gaming/` | 32-bit graphics and audio, Steam controller udev rules, GameMode, Gamescope and the `Steam (user profile)` session |
| User clients | `modules/home/gaming/` | Steam, Proton-GE, Lutris, Heroic, Wine/Winetricks, ProtonUp-Qt, ProtonPlus, MangoHud, GOverlay |

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

## Zenbook

The Zenbook has no gaming profile. Add `profiles/gaming.nix` and
`modules/home/gaming` deliberately if games should run on the eGPU (see
[installation-laptop](installation-laptop.md#nvidia-egpu)).
