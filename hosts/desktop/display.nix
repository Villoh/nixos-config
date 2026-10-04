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

    -- Place the initial cursor on DP-1, not the first detected output.
    hl.config({ cursor = { default_monitor = "DP-1" } })

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

  # Loaded after DMS output rules for every user's session on this host.
  environment.etc."xdg/hypr/host.lua".text = ''
    -- Place the initial cursor on DP-1, not the first detected output.
    hl.config({ cursor = { default_monitor = "DP-1" } })

    -- Mixed-DPI XWayland apps handle their own scale on this host.
    hl.config({ xwayland = { force_zero_scaling = true } })

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
}
