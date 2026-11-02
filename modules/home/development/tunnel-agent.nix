{ pkgs, ... }:

let
  inherit (pkgs) tunnel-agent;
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
