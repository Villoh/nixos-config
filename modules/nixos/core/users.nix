{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.groups.al68 = { };

  users.users.mikel = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Mikel";
    extraGroups = [
      "networkmanager"
      "wheel"
      "al68"
    ];
  };
}
