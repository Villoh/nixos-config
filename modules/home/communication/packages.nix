{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    packages = [
      {
        flatpakref = "https://hylki.hyprlab.co/flatpak/co.hyprlab.Hylki.flatpakref";
        sha256 = "0rgbr4hf27j1g7s1grdvbi94m7m9hbmyv6fb1ar1lf8sdd3bcas6";
      }
    ];
  };

  home.packages = with pkgs; [
    vesktop
    equibop
    legcord
    meli
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
  ];
}
