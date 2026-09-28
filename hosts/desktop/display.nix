{ lib, ... }:

{
  # DankGreeter runs in separate Hyprland; keep its output/focus host-specific.
  services.displayManager.dms-greeter.compositor.customConfig = lib.mkAfter ''
    -- Wayland has no primary-output setting; focus DP-1 for the greeter.
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprctl dispatch focusmonitor DP-1")
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

    -- Wayland has no primary-output setting; focus DP-1 for the desktop.
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprctl dispatch focusmonitor DP-1")
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
