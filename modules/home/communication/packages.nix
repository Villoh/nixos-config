{ inputs, pkgs, ... }:

let
  flectarMail = pkgs.flectar-mail;
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    # Flatpak on NixOS can't resolve /etc/localtime, so the sandbox falls back to UTC.
    overrides."co.hyprlab.Hylki".Environment.TZ = "Europe/Madrid";
    overrides."com.flectar.mail".Environment.TZ = "Europe/Madrid";
    overrides."com.cherry_ai.CherryStudio".Environment.TZ = "Europe/Madrid";
    overrides."cz.viceverse.serein".Environment.TZ = "Europe/Madrid";
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
  # into the host's so host apps (music players, games) can reach it.
  systemd.user.tmpfiles.rules = [
    "L %t/discord-ipc-0 - - - - .flatpak/cz.viceverse.serein/xdg-run/discord-ipc-0"
  ];

  home.packages = with pkgs; [
    meli
    himalaya
    telegram-desktop
    nchat
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
    # Disabled: the host build has no app ID, so Wayland global shortcuts never register
    # (ViceVerse-cz/Serein#905). Serein runs from Flatpak above; re-enable once fixed upstream.
    # inputs.serein.packages.${pkgs.stdenv.hostPlatform.system}.serein
    # Fallback client (beta; compiles libwebrtc/Skia).
    inputs.yapfast.packages.${pkgs.stdenv.hostPlatform.system}.yapfast
  ];
}
