{ pkgs, ... }:

{
  home.packages = with pkgs; [
    filen-cli
    # Upstream targets Electron ^43; nixpkgs' default electron (45) removed
    # app.isUnityRunning and filen-desktop crashes on load. Drop when fixed upstream.
    # Hyprland ignores minimize, so Super+Q left the window open with tray mode on;
    # hide it to the tray instead. Drop when upstream hides on Linux.
    ((filen-desktop.override { electron = electron_43; }).overrideAttrs (old: {
      postPatch = old.postPatch + ''
        substituteInPlace src/index.ts \
          --replace-fail 'this.driveWindow?.minimize()' 'this.driveWindow?.hide()'
      '';
    }))
  ];
}
