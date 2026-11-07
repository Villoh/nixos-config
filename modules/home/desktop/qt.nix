{ config, pkgs, ... }:

let
  # KDE apps set cwd but pass no args; Ghostty opens in ~ unless told the
  # directory explicitly. Default terminal comes from defaults.nix.
  terminal = pkgs.writeShellScript "kde-terminal" ''
    exec ${config.home.sessionVariables.TERMINAL} \
      --working-directory="$PWD" "$@"
  '';
in
{
  qt = {
    enable = true;
    # DMS manages ~/.config/qtengine/config.json for dynamic colors and icons.
    platformTheme = {
      name = "qtengine";
      package = pkgs.qtengine;
    };
    # Keep Breeze for both Qt5 and Qt6 independently of the generated config.
    style.name = "breeze";
    kde.settings = {
      kdeglobals.Icons.Theme = "Colloid-Dark";
      # KDE apps default to konsole for "open terminal", which isn't installed.
      kdeglobals.General.TerminalApplication = "${terminal}";
    };
  };
}
