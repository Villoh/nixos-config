{ inputs, pkgs, ... }:

let
  flectarMail = pkgs.flectar-mail;
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    # Flatpaks only update with `flatpak update` (Hylki lagged several releases). Enable ONE:
    # update.onActivation = true; # on every `nh os switch`, so it needs the network
    # update.auto = { enable = true; onCalendar = "weekly"; }; # on its own, once a week
    # Flatpak on NixOS can't resolve /etc/localtime, so the sandbox falls back to UTC.
    overrides."co.hyprlab.Hylki".Environment.TZ = "Europe/Madrid";
    overrides."com.flectar.mail".Environment.TZ = "Europe/Madrid";
    overrides."com.cherry_ai.CherryStudio".Environment.TZ = "Europe/Madrid";
    overrides."cz.viceverse.serein".Environment.TZ = "Europe/Madrid";
    # Closing (Super+Q) parks the window in the tray through Hyprland's IPC socket; without
    # it the sandboxed Serein can't hide on Wayland and the close is silently ignored.
    overrides."cz.viceverse.serein".Context.filesystems = [ "xdg-run/hypr" ];
    packages = [
      {
        flatpakref = "https://hylki.hyprlab.co/flatpak/co.hyprlab.Hylki.flatpakref";
        sha256 = "0rgbr4hf27j1g7s1grdvbi94m7m9hbmyv6fb1ar1lf8sdd3bcas6";
      }
      {
        appId = "com.flectar.mail";
        bundle = "${flectarMail}/share/flatpak/flectar-mail.flatpak";
        # nix-flatpak only installs bundles when sha256 changes (null -> null never installs).
        sha256 = "${flectarMail}";
      }
      {
        # Flatpak instead of the Nix build: the sandbox gives Serein an app ID, which it
        # needs to register its global shortcuts with the portal (ViceVerse-cz/Serein#905).
        flatpakref = "https://viceverse-cz.github.io/Serein/flatpak/serein.flatpakref";
        sha256 = "1ya81bdniq4rr0cn0cqs7qygxkrx9li9bwd7ycj50gmx34gnb9wn";
      }
      # nixpkgs builds the legacy Sciter UI, which lacks the third-party login the public server requires.
      "com.rustdesk.RustDesk"
      # nixpkgs ships Cherry Studio 1.9.11 on EOL Electron 40 (marked insecure); Flathub tracks 2.x.
      "com.cherry_ai.CherryStudio"
    ];
  };

  # Serein's Game Activity socket lives in the Flatpak's private runtime dir; link it
  # into the host's so host apps (music players, games) can reach it. The tray icon
  # (IconThemePath=%t/serein-tray-icons) has the same problem: the shell shows an "S" fallback.
  systemd.user.tmpfiles.rules = [
    "L %t/discord-ipc-0 - - - - .flatpak/cz.viceverse.serein/xdg-run/discord-ipc-0"
    "L %t/serein-tray-icons - - - - .flatpak/cz.viceverse.serein/xdg-run/serein-tray-icons"
  ];

  home.packages = with pkgs; [
    meli
    himalaya
    telegram-desktop
    nchat
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    # PENDING: cache. Source build, swapped for the prebuilt release meanwhile.
    # inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
    zapfast-bin
    # PENDING: cache + upstream. Disabled: the host build compiles locally (764 derivations) and
    # has no app ID, so Wayland global shortcuts never register (ViceVerse-cz/Serein#905).
    # To switch: uncomment this, drop the Flatpak entry, the TZ/hypr overrides and the two
    # tmpfiles links above, and point `launch` in hyprland.nix at `serein`.
    # The input is wired and evaluates; only the cache and #905 are missing.
    # inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.serein
    # Fallback client (beta; compiles libwebrtc/Skia).
    # PENDING: cache. Source build, swapped for the prebuilt release meanwhile.
    # inputs.yapfast.packages.${pkgs.stdenv.hostPlatform.system}.yapfast
    yapfast-bin
  ];
}
