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
      mode = "3840x2160@160",
      position = "0x0",
      scale = 1.5,
    })
    hl.monitor({
      output = "HDMI-A-1",
      mode = "3840x2160@59.997",
      position = "2560x0",
      scale = 1.5,
    })
  '';

  # Loaded after DMS output rules for every user's session on this host.
  environment.etc."xdg/hypr/host.lua".text = ''
    -- Place the initial cursor on DP-1, not the first detected output.
    hl.config({ cursor = { default_monitor = "DP-1" } })

    -- Mixed-DPI XWayland apps handle their own scale on this host.
    hl.config({ xwayland = { force_zero_scaling = true } })

    -- Electron apps (Codex, Claude) trigger auto HDR on fullscreen, which turns on
    -- wide gamut, and shows a warning on 8-bit outputs. 1 = HDR for fullscreen HDR
    -- content (games), 0 = never.
    hl.config({ render = { cm_auto_hdr = 1 } })

    -- XWayland marks no primary output, so Wine/Proton games pick HDMI-A-1.
    hl.on("hyprland.start", function()
      hl.exec_cmd("${pkgs.xrandr}/bin/xrandr --output DP-1 --primary")
    end)

    -- Only DP-1 (TCL 27C2A) runs 10-bit: HDMI-A-1 (Acer) is HDMI 2.0, which has no
    -- bandwidth for 4K60 10-bit RGB. HDR is not forced on the desktop (it looked dim
    -- and washed out); cm_auto_hdr above turns it on for fullscreen HDR content.
    hl.monitor({
      output = "DP-1",
      mode = "3840x2160@160",
      position = "0x0",
      scale = 1.5,
      bitdepth = 10,
    })
    hl.monitor({
      output = "HDMI-A-1",
      mode = "3840x2160@59.997",
      position = "2560x0",
      scale = 1.5,
    })
  '';
}
