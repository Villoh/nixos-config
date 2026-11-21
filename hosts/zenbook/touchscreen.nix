# Touchscreen gestures. Hyprland only turns touchpad swipes into gestures (gestures.nix in
# modules/home/desktop/hyprland); hyprgrass does the same for the touchscreen (WDHT1F01,
# 10 contacts). The plugin loads before extraConfig, so the guard below only skips the
# gestures if it failed to load.
#
# Fingers  Gesture                  Action
#   3      swipe left/right         switch workspace, following the fingers
#   3      tap                      toggle floating
#   3      long press, then drag    move the window
#
# Touchscreen and touchpad do not share gestures: this table is the whole touchscreen set.
# The touchpad's (3 and 4 fingers, plus SUPER/ALT/CTRL/SHIFT planes) are in gestures.nix.
{ lib, pkgs, ... }:

{
  home-manager.users.mikel.wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprgrass ];
    extraConfig = lib.mkAfter ''
      -- Touchscreen gestures (hosts/zenbook/touchscreen.nix).
      if hl.plugin.hyprgrass ~= nil then
        hl.config({ plugin = { hyprgrass = { sensitivity = 4.0 } } })

        hl.plugin.hyprgrass.gesture({
          pattern = { kind = "swipe", fingers = 3, direction = "horizontal" },
          action = "workspace",
        })
        hl.plugin.hyprgrass.bind({
          pattern = { kind = "tap", fingers = 3 },
          action = hl.dsp.window.float(),
        })
        hl.plugin.hyprgrass.bind({
          pattern = { kind = "longpress", fingers = 3 },
          action = hl.dsp.window.drag(),
          mouse = true,
        })
      end
    '';
  };
}
