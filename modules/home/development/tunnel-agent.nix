{ pkgs, ... }:

let
  tunnel-agent = pkgs.appimageTools.wrapType2 {
    pname = "tunnel-agent";
    version = "1.1.6";
    src = pkgs.fetchurl {
      url = "https://github.com/Villoh/tunnel-agent/releases/download/v1.1.6/TunnelAgent-1.1.6-linux-x64.AppImage";
      hash = "sha256-SDnGeIwzpb63sv/mMDRDdvdHD7/Ib5JkU3HMdI5hv0o=";
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
      exec = "tunnel-agent";
      terminal = false;
      categories = [ "Utility" "Development" ];
    };
  };
}
