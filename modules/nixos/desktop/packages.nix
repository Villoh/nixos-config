{ pkgs, ... }:

{
  # A usable terminal and Qt integration must exist before any HM profile.
  environment.systemPackages = with pkgs; [
    ghostty
    qtengine
    # Strata resolves provider interpreters only from system directories, never from
    # the per-user profile. Its KDE Connect integration (Settings > Integrations) needs
    # a python3 with PyGObject (`gi`). Your dev python3 (home profile) stays untouched.
    # Alternative without a system python3: modules/home/desktop/strata-kdeconnect.nix.
    (python3.withPackages (ps: [ ps.pygobject3 ]))
  ];

  qt = {
    enable = true;
    style = "breeze";
  };
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qtengine";
}
