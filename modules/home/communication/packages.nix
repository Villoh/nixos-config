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
      # nixpkgs builds the legacy Sciter UI, which lacks the third-party login the public server requires.
      "com.rustdesk.RustDesk"
      # nixpkgs ships Cherry Studio 1.9.11 on EOL Electron 40 (marked insecure); Flathub tracks 2.x.
      "com.cherry_ai.CherryStudio"
    ];
  };

  home.packages = with pkgs; [
    vesktop
    equibop
    meli
    himalaya
    telegram-desktop
    nchat
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
  ];
}
