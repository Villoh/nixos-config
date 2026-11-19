{ lib, ... }:

{
  # Zenbook default: Spanish keyboard. The external US keyboard (AL68) is pinned
  # to US International.
  environment.etc."xdg/hypr/host.lua".text = ''
    hl.config({
      input = {
        kb_layout = "es",
        kb_variant = "",
        kb_options = "",
      },
    })
    for _, name in ipairs({
      "smartcloud-al68-keyboard", "smartcloud-al68-keyboard-1",
      "i-chip-yunzii-al68-2.4g", "i-chip-yunzii-al68-2.4g-keyboard", "i-chip-yunzii-al68-2.4g-keyboard-1",
    }) do
      hl.device({ name = name, kb_layout = "us", kb_variant = "intl", kb_options = "" })
    end
  '';

  # Binds resolve against the first layout (es), for every keyboard. DMS binds that sit on
  # a shifted or AltGr key there (Slash, bracketleft/right, equal) fire on the wrong key or
  # never. Same actions on letters, which sit in the same place on both keyboards
  # (punctuation does not: es minus is the US slash key). Separate from host.lua, which the
  # greeter loads too; the user session requires this one (hyprland/default.nix).
  environment.etc."xdg/hypr/host-binds.lua".text = ''
    hl.bind("SUPER + CTRL + K", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"), { description = "Keybindings" })
    hl.bind("SUPER + ALT + Q", hl.dsp.layout("preselect l"), { description = "Preselect left" })
    hl.bind("SUPER + ALT + E", hl.dsp.layout("preselect r"), { description = "Preselect right" })
    hl.bind("SUPER + ALT + W", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true, description = "Grow window width" })
    hl.bind("SUPER + ALT + H", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true, description = "Grow window height" })
  '';

  services.displayManager.dux-greeter.compositor.customConfig = lib.mkAfter ''
    require("/etc/xdg/hypr/host")
  '';
}
