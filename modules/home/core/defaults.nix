{ lib, ... }:

let
  sessionVariables = {
    EDITOR = "zeditor";
    VISUAL = "zeditor";
    BROWSER = "zen";
    TERMINAL = "ghostty";
    EXPLORER = "dolphin";
    PAGER = "less";
    FILE_MANAGER = "dolphin";
    DISCORD = "vesktop";
    # Ask Nix-packaged Electron apps to use native Wayland.
    NIXOS_OZONE_WL = "1";
  };
  uwsmEnvironment = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") sessionVariables
  ) + "\n";
in
{
  home-manager.users.mikel = {
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/pnpm/bin"
    ];

    home.sessionVariables = sessionVariables;
    xdg.configFile."uwsm/env".text = uwsmEnvironment;
  };
}
