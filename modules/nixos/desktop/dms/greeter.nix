{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.displayManager.dux-greeter;
in
{
  programs.hyprland.enable = true;
  environment.systemPackages = [ pkgs.bibata-cursors ];

  services.displayManager.dux-greeter = {
    enable = true;
    compositor.name = "hyprland";
    # The shell's `dms` wrapper adds these image plugins; the greeter runs plain
    # quickshell, so a .webp or .avif wallpaper would not load there. Set them in
    # the greeter's Hyprland, not with quickshell.package: the module appends that
    # to PATH, after the system quickshell that PAM's PATH already has.
    compositor.customConfig = ''
      hl.env("QT_PLUGIN_PATH", "${
        lib.makeSearchPath "lib/qt-6/plugins" [
          pkgs.qt6.qtimageformats
          pkgs.kdePackages.kimageformats
        ]
      }")
    '';
  };

  # nixpkgs' sync hook copies already-cached themes/wallpapers onto themselves.
  # With no import sources, leave the prepared cache alone; tmpfiles owns its dir.
  systemd.services.greetd.preStart = lib.mkIf (
    cfg.enable && cfg.configHome == null && cfg.configFiles == [ ]
  ) (lib.mkForce "");
}
