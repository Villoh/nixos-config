{ lib, ... }:

{
  # Zenbook default: Spanish keyboard.  Alt+Shift switches to US
  # International for an external US keyboard.
  environment.etc."xdg/hypr/host.lua".text = ''
    hl.config({
      input = {
        kb_layout = "es,us",
        kb_variant = ",intl",
        kb_options = "grp:alt_shift_toggle",
      },
    })
  '';

  services.displayManager.dms-greeter.compositor.customConfig = lib.mkAfter ''
    require("/etc/xdg/hypr/host")
  '';
}
