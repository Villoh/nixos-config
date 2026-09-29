{ pkgs, ... }:

let
  tunnel-agent = pkgs.appimageTools.wrapType2 {
    pname = "tunnel-agent";
    version = "1.1.7";
    src = pkgs.fetchurl {
      url = "https://github.com/beyondhumane/tunnel-agent/releases/download/v1.1.7/TunnelAgent-1.1.7-linux-x64.AppImage";
      hash = "sha256-r9mx4jM2Jbd44QQHjOkkWmr7pfYoDLMXi8em2lrCV+Q=";
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
      exec = "${tunnel-agent}/bin/tunnel-agent";
      terminal = false;
      categories = [
        "Utility"
        "Development"
      ];
    };
  };
}
