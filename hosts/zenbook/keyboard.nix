{ lib, ... }:

{
  # Zenbook default: Spanish keyboard, US International as second layout
  # (Alt+Shift or the DMS bar widget).  The external US keyboard is pinned to
  # US International so it never depends on the toggle state.
  environment.etc."xdg/hypr/host.lua".text = ''
    hl.config({
      input = {
        kb_layout = "es,us",
        kb_variant = ",intl",
        kb_options = "grp:alt_shift_toggle",
      },
    })
    for _, name in ipairs({ "smartcloud-al68-keyboard", "smartcloud-al68-keyboard-1" }) do
      hl.device({ name = name, kb_layout = "us", kb_variant = "intl", kb_options = "" })
    end
  '';

  services.displayManager.dux-greeter.compositor.customConfig = lib.mkAfter ''
    require("/etc/xdg/hypr/host")
  '';
}
