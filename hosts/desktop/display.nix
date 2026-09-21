{ ... }:

{
  # DMS may retain positions for disconnected outputs. Keep this host's
  # DisplayPort monitor left and HDMI monitor right.
  home-manager.users.mikel.wayland.windowManager.hyprland.extraConfig = ''
    hl.monitor({
      output = "DP-1",
      mode = "preferred",
      position = "0x0",
      scale = 1,
    })
    hl.monitor({
      output = "HDMI-A-1",
      mode = "1920x1080@60.000",
      position = "1920x0",
      scale = 1,
    })

    -- Keep workspaces 1-5 on the primary DisplayPort monitor and use 6 as the
    -- default workspace on the secondary HDMI monitor.
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
