{ lib, ... }:

{
  # DankGreeter runs in separate Hyprland; keep its output/focus host-specific.
  services.displayManager.dms-greeter.compositor.customConfig = lib.mkAfter ''
    -- Start on DP-1; Wayland has no primary-output setting.
    hl.workspace_rule({
      workspace = "1",
      monitor = "DP-1",
      default = true,
    })
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprctl dispatch workspace 1")
    end)

    hl.monitor({
      output = "DP-1",
      mode = "1920x1080@239.760",
      position = "0x0",
      scale = 1,
    })
    hl.monitor({
      output = "HDMI-A-1",
      mode = "3840x2160@59.997",
      position = "1920x-360",
      scale = 1.5,
    })
  '';

  # DMS owns generated output rules; pin this host's modes/layout after them.
  # Other DMS settings remain active.
  home-manager.users.mikel.wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    hl.monitor({
      output = "DP-1",
      mode = "1920x1080@239.760",
      position = "0x0",
      scale = 1,
    })
    hl.monitor({
      output = "HDMI-A-1",
      mode = "3840x2160@59.997",
      position = "1920x-360",
      scale = 1.5,
    })

    -- Start on workspace 1, pinned to DP-1; Wayland has no primary-output setting.
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprctl dispatch workspace 1")
    end)

    -- Keep workspaces 1-5 on DP-1 and use 6 as the default workspace on HDMI-A-1.
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
