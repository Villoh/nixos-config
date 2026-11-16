{ pkgs, ... }:

{
  home.packages = with pkgs; [
    filen-cli
    # Upstream targets Electron ^43; nixpkgs' default electron (45) removed
    # app.isUnityRunning and filen-desktop crashes on load. Drop when fixed upstream.
    (filen-desktop.override { electron = electron_43; })
  ];
}
