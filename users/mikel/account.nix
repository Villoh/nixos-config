{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.mikel = {
    isNormalUser = true;
    home = "/home/mikel";
    shell = pkgs.zsh;
    description = "Mikel";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
