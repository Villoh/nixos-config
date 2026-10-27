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

  # Overrides the entry Tern writes itself, whose Exec bypasses the wrapper.
  xdg.desktopEntries."so.stencil.tern" = {
    name = "Tern";
    comment = "Multiplexing terminal";
    exec = "${lib.getExe tern}";
    icon = "so.stencil.tern";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    settings = {
      StartupWMClass = "so.stencil.tern";
      X-TerminalArgExec = "-e";
    };
  };
}
