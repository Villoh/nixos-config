{ ... }:

{
  # Desk monitors, matched by EDID description so the layout follows them
  # through any port, dock or eGPU. The internal panel is off only while the lid
  # is closed with any other monitor connected (clamshell). Otherwise it stays
  # on: at the desk it is workspace 11 and a lifeline if the eGPU crashes, and at
  # work it is a normal second screen. Merged with keyboard.nix; the greeter
  # already requires this file.
  environment.etc."xdg/hypr/host.lua".text = builtins.readFile ./display.lua;
}
