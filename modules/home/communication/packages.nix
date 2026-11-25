{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    # Flatpaks only update with `flatpak update` (Hylki lagged six releases). Enable ONE:
    # update.onActivation = true; # on every `nh os switch`, so it needs the network
    # update.auto = { enable = true; onCalendar = "weekly"; }; # on its own, once a week
    # Flatpak on NixOS can't resolve /etc/localtime, so the sandbox falls back to UTC.
    overrides."co.hyprlab.Hylki".Environment.TZ = "Europe/Madrid";
    # Black window: the sandbox has no NVIDIA GL for the host driver, so Mesa cannot create a
    # screen for the RTX 3080 ("MESA-EGL: failed to create dri2 screen"). Draw with Cairo.
    # Drop if the org.freedesktop.Platform.GL.nvidia runtime matching the driver is installed.
    overrides."co.hyprlab.Hylki".Environment.GSK_RENDERER = "cairo";
    # Hylki (GTK4/libadwaita) reads DMS/Matugen colours from the host's gtk-4.0 dir.
    overrides."co.hyprlab.Hylki".Context.filesystems = [ "xdg-config/gtk-4.0:ro" ];
    overrides."com.cherry_ai.CherryStudio".Environment.TZ = "Europe/Madrid";
    packages = [
      {
        flatpakref = "https://hylki.hyprlab.co/flatpak/co.hyprlab.Hylki.flatpakref";
        sha256 = "0rgbr4hf27j1g7s1grdvbi94m7m9hbmyv6fb1ar1lf8sdd3bcas6";
      }
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
    # Native .deb, not the Flatpak (no clipboard on Wayland, see packages/flectar-mail). Stays
    # until upstream ships a flake.
    flectar-mail
  ];
}
