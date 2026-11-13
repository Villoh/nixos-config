{ lib, pkgs, ... }:

{
  # Acid Boot sizes its logo from the largest output (the 4K HDMI) and centers the
  # 1080p DP-1 in that canvas, cropping it. Equal sizes during boot avoid that;
  # Hyprland sets the real modes later.
  boot.kernelParams = [ "video=HDMI-A-1:1920x1080@60" ];

  # Dux Greeter runs in separate Hyprland; keep its output/focus host-specific.
  services.displayManager.dux-greeter.compositor.customConfig = lib.mkAfter ''
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

    -- Electron apps (Codex, Claude) request wide gamut on fullscreen, but the
    -- outputs run 8-bit sRGB, which triggers a warning. Remove this to use HDR.
    hl.config({ render = { cm_enabled = false } })

    -- XWayland marks no primary output, so Wine/Proton games pick HDMI-A-1.
    hl.on("hyprland.start", function()
      hl.exec_cmd("${pkgs.xrandr}/bin/xrandr --output DP-1 --primary")
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
}
