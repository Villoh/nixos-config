{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.mikel = {
    isNormalUser = true;
    home = "/home/mikel";
    shell = pkgs.zsh;
    description = "Mikel";
    extraGroups = [
      # Mechvibes reads keystrokes from /dev/input. Any process of this user can then log every
      # key, passwords included.
      "input"
      "networkmanager"
      "wheel"
    ];
  };
}
