{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    # Flatpaks only update with `flatpak update`. Enable ONE:
    # update.onActivation = true; # on every `nh os switch`, so it needs the network
    # update.auto = { enable = true; onCalendar = "weekly"; }; # on its own, once a week
    # Flatpak on NixOS can't resolve /etc/localtime, so the sandbox falls back to UTC.
    overrides."com.cherry_ai.CherryStudio".Environment.TZ = "Europe/Madrid";
    packages = [
      # nixpkgs ships Cherry Studio 1.9.11 on EOL Electron 40 (marked insecure); Flathub tracks 2.x.
      "com.cherry_ai.CherryStudio"
      # PDF text editor; not in nixpkgs.
      "io.github.word_sys.word-sys-pdf-editor"
    ];
  };

  home.packages = with pkgs; [
    meli
    himalaya
    telegram-desktop
    nchat
    # `rustdesk` is the legacy Sciter UI, which lacks the third-party login the public server
    # requires; `rustdesk-flutter` is the current one and is in cache.nixos.org.
    rustdesk-flutter
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    zapfast
    # PENDING: cache. Source build (764 derivations), swapped for the prebuilt nightly meanwhile.
    # Not the Flatpak: its PID namespace breaks the tray hide (Serein sends Hyprland its sandbox
    # PID). Global shortcuts need a rev with ViceVerse-cz/Serein#906.
    # inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.serein
    serein-bin
    # Fallback client (beta; compiles libwebrtc/Skia).
    # PENDING: cache. Source build, swapped for the prebuilt release meanwhile.
    # inputs.yapfast.packages.${pkgs.stdenv.hostPlatform.system}.yapfast
    yapfast-bin
    # Fluxer client (official .deb via a community flake, see flake.nix).
    inputs.fluxer.packages.${pkgs.stdenv.hostPlatform.system}.fluxer
    # Native .deb, not the Flatpak (no clipboard on Wayland, see packages/flectar-mail). Stays
    # until upstream ships a flake.
    flectar-mail
    # Native .deb (beta, Microsoft accounts first); upstream ships no flake.
    mailcraft
  ];
}
