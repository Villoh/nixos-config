{ ... }:

{
  programs.kdeconnect.enable = true;

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  imports = [
    ./packages.nix
    ./dms-greeter.nix
    ./dms.nix
    ./hyprland.nix
    ./portals.nix
  ];
}
