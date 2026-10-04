{ pkgs, ... }:

let
  tunnel-agent = pkgs.appimageTools.wrapType2 {
    pname = "tunnel-agent";
    version = "1.1.11";
    src = pkgs.fetchurl {
      url = "https://github.com/beyondhumane/tunnel-agent/releases/download/v1.1.11/TunnelAgent-1.1.11-linux-x64.AppImage";
      hash = "sha256-pyEpfsaGAftF4sxXOWLcnxRV9phK6iYGEQrTcmBot5Y=";
    };
    extraPkgs = pkgs: [ pkgs.icu ];
  };
in
{
  home-manager.users.mikel = {
    home.packages = [ tunnel-agent ];

    xdg.desktopEntries.tunnel-agent = {
      name = "Tunnel Agent";
      comment = "Desktop UI for local AI provider gateways";
      # Avalonia is X11-only; with force_zero_scaling it needs per-output scale.
      exec = "env \"AVALONIA_SCREEN_SCALE_FACTORS=DP-1=1;HDMI-A-1=1.5\" ${tunnel-agent}/bin/tunnel-agent";
      terminal = false;
      categories = [
        "Utility"
        "Development"
      ];
    };
  };
}
