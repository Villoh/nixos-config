{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    packages = [
      {
        flatpakref = "https://github.com/gxanshu/postcard/releases/download/v1.13.0/postcard.flatpakref";
        sha256 = "11j0cbgl2wrqnh98xlb5pb82m70qd79ypl2q7hy2kqfzri308qn6";
      }
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
    inputs.zapfast.packages.${pkgs.stdenv.hostPlatform.system}.zapfast
  ];
}
