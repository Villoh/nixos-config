{ pkgs, ... }:

let
  tunnel-agent = pkgs.appimageTools.wrapType2 {
    pname = "tunnel-agent";
    version = "1.1.12";
    src = pkgs.fetchurl {
      url = "https://github.com/beyondhumane/tunnel-agent/releases/download/v1.1.12/TunnelAgent-1.1.12-linux-x64.AppImage";
      hash = "sha256-DRQN2BgmJTbKIaHh0hX8iSxeKDgwONbzZQWfNXMWKMg=";
    };
    extraPkgs = pkgs: [ pkgs.icu ];
  };
in
{
  home.packages = [ tunnel-agent ];

  xdg.desktopEntries.tunnel-agent = {
    name = "Tunnel Agent";
    comment = "Desktop UI for local AI provider gateways";
    # Per-output Avalonia scaling belongs in the host's session environment.
    exec = "${tunnel-agent}/bin/tunnel-agent";
    terminal = false;
    categories = [
      "Utility"
      "Development"
    ];
  };
}
