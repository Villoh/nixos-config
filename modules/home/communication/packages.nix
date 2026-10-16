{ inputs, pkgs, ... }:

let
  flectarMail = pkgs.fetchurl {
    url = "https://github.com/flectar/mail/releases/download/v0.1.0-alpha.7/flectar-mail-0.1.0-alpha.7-linux-x64.flatpak";
    hash = "sha256-tDlFa59TaEylVGSi+w1YuK7eXd8eDrT4Hm4l66s6b5U=";
  };
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    # Flatpak on NixOS can't resolve /etc/localtime, so the sandbox falls back to UTC.
    overrides."co.hyprlab.Hylki".Environment.TZ = "Europe/Madrid";
    overrides."com.flectar.mail".Environment.TZ = "Europe/Madrid";
    packages = [
      {
        flatpakref = "https://hylki.hyprlab.co/flatpak/co.hyprlab.Hylki.flatpakref";
        sha256 = "0rgbr4hf27j1g7s1grdvbi94m7m9hbmyv6fb1ar1lf8sdd3bcas6";
      }
      {
        appId = "com.flectar.mail";
        bundle = "${flectarMail}";
        # nix-flatpak only installs bundles when sha256 changes (null -> null never installs).
        sha256 = "${flectarMail}";
      }
    ];
  };

  home.packages = with pkgs; [
    equibop
    meli
    himalaya
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
  ];
}
