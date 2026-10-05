{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.displayManager.dms-greeter;
in
{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
  };

  # nixpkgs' sync hook copies already-cached themes/wallpapers onto themselves.
  # With no import sources, leave the prepared cache alone; tmpfiles owns its dir.
  systemd.services.greetd.preStart = lib.mkIf (
    cfg.enable && cfg.configHome == null && cfg.configFiles == [ ]
  ) (lib.mkForce "");
}
