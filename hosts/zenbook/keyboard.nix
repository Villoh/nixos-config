{ ... }:

{
  # Zenbook default: Spanish keyboard.  Alt+Shift switches to US
  # International for an external US keyboard.
  home-manager.users.mikel.wayland.windowManager.hyprland.extraConfig = ''
    hl.config({
      input = {
        kb_layout = "es,us",
        kb_variant = ",intl",
        kb_options = "grp:alt_shift_toggle",
      },
    })
  '';
}
