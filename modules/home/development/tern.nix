{ lib, pkgs, ... }:

# Tern is a prebuilt, self-updating binary installed by hand in
# ~/.local/opt/tern (download needs a build.stencil.so login). This only
# supplies the GUI libraries it needs, scoped to Tern instead of the global
# programs.nix-ld.libraries. Requires programs.nix-ld.enable.
let
  libs = with pkgs; [
    libxcb
    libx11
    libxcursor
    libxi
    libxrandr
    libxext
    libxfixes
    libxrender
    libxinerama
    libxkbcommon
    wayland
    libglvnd
    mesa
    vulkan-loader
    fontconfig
    freetype
    libpulseaudio
    linux-pam
    dbus
  ];

  tern = pkgs.writeShellApplication {
    name = "tern";
    runtimeInputs = [ pkgs.glib ]; # gdbus
    text = ''
      export NIX_LD_LIBRARY_PATH=${lib.makeLibraryPath libs}''${NIX_LD_LIBRARY_PATH:+:$NIX_LD_LIBRARY_PATH}
      exec "$HOME/.local/opt/tern/tern" "$@"
    '';
  };
in
{
  home.packages = [ tern ];

  # Replaces the entry Tern writes itself, whose Exec bypasses the wrapper. It
  # must live in ~/.local/share/applications (not a profile) because that dir
  # shadows XDG_DATA_DIRS; force overwrites Tern's regular file.
  xdg.dataFile."applications/so.stencil.tern.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Tern
      Comment=Multiplexing terminal
      Exec=${lib.getExe tern}
      Icon=so.stencil.tern
      StartupWMClass=so.stencil.tern
      Terminal=false
      Categories=System;TerminalEmulator;
      X-TerminalArgExec=-e
    '';
  };
}
