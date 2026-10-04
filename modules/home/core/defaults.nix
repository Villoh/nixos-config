{ config, lib, ... }:

let
  sessionVariables = {
    EDITOR = "zeditor";
    VISUAL = "zeditor";
    BROWSER = "zen";
    TERMINAL = "ghostty";
    EXPLORER = "dolphin";
    PAGER = "less";
    FILE_MANAGER = "dolphin";
    # Override UWSM's compositor-derived prefix after its defaults are loaded.
    XDG_MENU_PREFIX = "plasma-";
    DISCORD = "equibop";
    # Ask Nix-packaged Electron apps to use native Wayland.
    NIXOS_OZONE_WL = "1";
  };
  uwsmEnvironment =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "export ${name}=${lib.escapeShellArg (toString value)}"
      ) config.home.sessionVariables
    )
    + "\n";
in
{
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.dataHome}/pnpm/bin"
  ];

  home.sessionVariables = sessionVariables;
  xdg.configFile."uwsm/env".text = uwsmEnvironment;
}
