{ inputs, pkgs, ... }:

let
  # OBS zoom-to-mouse for Hyprland (xevrion fork of BlankSourceCode/obs-zoom-to-mouse), audited
  # 2026-11-28: its only popen is `hyprctl cursorpos`; the UDP remote listener is opt-in. The
  # script hardcodes /usr/bin/hyprctl, which NixOS lacks.
  obsZoomToMouse =
    pkgs.runCommandLocal "obs-zoom-to-mouse-wayland.lua"
      {
        src = pkgs.fetchFromGitHub {
          owner = "xevrion";
          repo = "obs-zoom-to-mouse-wayland";
          rev = "39d606a525bd4adaf7cd682a229aab5584c37fe5";
          hash = "sha256-IHLzlI80RgmqkvDRB6Ji0a0Z1sYuF83Sl40HzT62ASY=";
        };
      }
      ''
        substitute $src/obs-zoom-to-mouse-wayland.lua $out \
          --replace-fail /usr/bin/hyprctl /run/current-system/sw/bin/hyprctl
      '';

  # affinity-nix's own pinned nixpkgs, unfree allowed: same derivations as cache.forall.systems.
  affinity =
    (import inputs.affinity-nix.inputs.nixpkgs {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [ inputs.affinity-nix.overlays.default ];
    }).affinity-v3;
in
{
  # Stable path for OBS: Tools > Scripts > + (once). Store path would change on every bump.
  xdg.configFile."obs-studio/scripts/obs-zoom-to-mouse-wayland.lua".source = obsZoomToMouse;

  home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.ytm-player-full
    inputs.sonora.packages.${pkgs.stdenv.hostPlatform.system}.sonora
    # Source build served by kopuz.cachix.org (modules/nixos/core/nix.nix).
    inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.kopuz
    # Affinity on Wine; needs the Serif installer from archive.org, fetched at build time.
    affinity
    # Native Rust image editor (PSD/PSB); photocraft-cli also serves MCP (photocraft-cli mcp).
    pkgs.photocraft
    # Rest of the ArtCraft "Crafting Apps" suite (early alpha, native Rust).
    pkgs.pdfcraft
    pkgs.gridcraft
    pkgs.deckcraft
    pkgs.wordcraft
    pkgs.filmcraft
    pkgs.soundcraft
    # Keyboard sound simulator (packages/mechvibes); needs the `input` group (users/mikel).
    pkgs.mechvibes
    pkgs.meiro
    pkgs.imv
    pkgs.mpv
    pkgs.wf-recorder
    # Screen recorder with auto-zoom and cursor effects (also exports GIF).
    pkgs.recordly
    # Simple Wayland recorder that writes GIF directly.
    pkgs.kooha
    # Video editors on trial: keep one, drop the other. Resolve is unfree; nixpkgs downloads
    # its ~4 GB installer from Blackmagic at build time.
    pkgs.kdePackages.kdenlive
    pkgs.davinci-resolve
    pkgs.ffmpeg
    pkgs.frame-media-converter
    pkgs.yt-dlp
    pkgs.imagemagick
    pkgs.img2pdf
    pkgs.tesseract
    pkgs.zbar
    # DMS Screen Capture Toolbar: capture, region selection, editor and notifications.
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.libnotify
  ];
}
