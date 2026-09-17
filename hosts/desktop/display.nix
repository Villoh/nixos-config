{ ... }:

{
  # Keep workspaces 1-5 on the primary DisplayPort monitor and use 6 as the
  # default workspace on the secondary HDMI monitor.
  home-manager.users.mikel.wayland.windowManager.hyprland.extraConfig = ''
    hl.workspace_rule({
      workspace = "1",
      monitor = "DP-1",
      default = true,
    })
    hl.workspace_rule({
      workspace = "6",
      monitor = "HDMI-A-1",
      default = true,
    })
  '';
}
