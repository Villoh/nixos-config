{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.mikel = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Mikel";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
