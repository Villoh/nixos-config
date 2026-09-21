{ inputs, ... }:

{
  home-manager.users.mikel = {
    imports = [ inputs.codex-desktop-linux.homeManagerModules.default ];
    programs.codexDesktopLinux.enable = true;
  };
}
