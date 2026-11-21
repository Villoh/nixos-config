# Touchscreen gestures. Hyprland only turns touchpad swipes into gestures; hyprgrass does the
# same for the touchscreen (WDHT1F01, 10 contacts). This loads the plugin (before extraConfig)
# and tunes it; the gestures are in modules/home/desktop/hyprland/touchscreen.nix, which
# hyprland/default.nix includes once it sees hyprgrass in `plugins`.
{ lib, pkgs, ... }:

{
  home-manager.users.mikel.wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprgrass ];
    extraConfig = lib.mkAfter ''
      if hl.plugin.hyprgrass ~= nil then
        -- sensitivity: upstream recommends 4 on screens; edge_margin: px from the border
        -- that count as an edge swipe.
        hl.config({ plugin = { hyprgrass = { sensitivity = 4.0, edge_margin = 30 } } })
      end
    '';
  };
}
