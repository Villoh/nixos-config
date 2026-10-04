{ lib, ... }:

{
  # UWSM imports these defaults; each user's environment may override them.
  environment.sessionVariables.TERMINAL = lib.mkDefault "ghostty";

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
