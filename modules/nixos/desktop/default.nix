{ lib, ... }:

{
  # UWSM imports these defaults; each user's environment may override them.
  environment.sessionVariables.TERMINAL = lib.mkDefault "ghostty";

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  # setcap wrapper for gsr-kms-server: without it, DMS recording (ALT+Print) asks for
  # pkexec, fails, and falls back to wf-recorder. Also installs gpu-screen-recorder.
  programs.gpu-screen-recorder.enable = true;

  imports = [
    ./packages.nix
    ./dms
    ./noctalia
    ./hyprland.nix
    ./portals.nix
  ];
}
