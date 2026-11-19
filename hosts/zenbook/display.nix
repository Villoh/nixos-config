{ ... }:

{
  # Desk monitors, matched by EDID description so the layout follows them
  # through any port, dock or eGPU. The internal panel is off while a desk
  # monitor is connected, or while the lid is closed with any other monitor
  # connected (clamshell). Otherwise it stays on, so with the lid open at work
  # the laptop is a normal second screen. Merged with keyboard.nix; the greeter
  # already requires this file.
  environment.etc."xdg/hypr/host.lua".text = builtins.readFile ./display.lua;
}
