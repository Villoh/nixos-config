{ lib, ... }:

{
  # Zenbook default: Spanish keyboard. The external US keyboard (AL68) is pinned
  # to US International.
  environment.etc."xdg/hypr/host.lua".text = builtins.readFile ./keyboard.lua;

  # Binds resolve against the first layout (es), for every keyboard. DMS binds that sit on
  # a shifted or AltGr key there (Slash, bracketleft/right, equal) fire on the wrong key or
  # never. Same actions on letters, which sit in the same place on both keyboards
  # (punctuation does not: es minus is the US slash key). Separate from host.lua, which the
  # greeter loads too; the user session requires this one (hyprland/default.nix).
  environment.etc."xdg/hypr/host-binds.lua".text = builtins.readFile ./keyboard-binds.lua;

  services.displayManager.dux-greeter.compositor.customConfig = lib.mkAfter ''
    require("/etc/xdg/hypr/host")
  '';
}
