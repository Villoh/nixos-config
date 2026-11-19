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

  # Installs OBS and v4l2loopback so "OBS Virtual Camera" shows up as a webcam in other apps.
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  imports = [
    ./packages.nix
    ./dms
    ./noctalia
    ./hyprland.nix
    ./portals.nix
  ];
}
