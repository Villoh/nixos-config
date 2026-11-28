{ lib, pkgs, ... }:

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

  # ShadowPlay-style overlay (gsr-ui): Left Alt+Z toggles it, instant replay and clip hotkeys
  # work over games. Adds the gsr-global-hotkeys setcap wrapper. Start it with `gsr-ui`.
  programs.gpu-screen-recorder.ui.enable = true;

  # Installs OBS and v4l2loopback so "OBS Virtual Camera" shows up as a webcam in other apps.
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    # With the NVIDIA driver, opening a projector makes OBS commit a surface with explicit sync
    # but no acquire point; Hyprland rejects it ("Missing acquire timeline") and closes OBS
    # (obs-studio #11022). Turn explicit sync off for OBS only; native Wayland stays.
    package = pkgs.symlinkJoin {
      inherit (pkgs.obs-studio) pname version meta;
      paths = [ pkgs.obs-studio ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/obs --set __NV_DISABLE_EXPLICIT_SYNC 1
      '';
    };
  };

  imports = [
    ./packages.nix
    ./dms
    ./noctalia
    ./hyprland.nix
    ./portals.nix
  ];
}
