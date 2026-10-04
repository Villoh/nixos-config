{ pkgs, ... }:

{
  # A usable terminal and Qt integration must exist before any HM profile.
  environment.systemPackages = with pkgs; [
    ghostty
    qtengine
  ];

  qt = {
    enable = true;
    style = "breeze";
  };
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qtengine";
}
