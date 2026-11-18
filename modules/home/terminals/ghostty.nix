{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Keep this per-user input-method fix; NixOS provides unwrapped Ghostty as a fallback.
  ghostty = pkgs.symlinkJoin {
    name = "ghostty-with-simple-im";
    meta.mainProgram = "ghostty";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/ghostty" --set GTK_IM_MODULE simple
    '';
  };
in
{
  programs.ghostty = {
    enable = true;
    package = ghostty;
    settings = {
      # DMS generates this theme dynamically through matugen.
      theme = "dankcolors";
      "font-family" = "JetBrainsMono Nerd Font";
      "font-size" = 10;
      "font-codepoint-map" = [
        "U+E1A0-U+E1B6=Herdr Agent Icons Max"
        "U+E1C0-U+E1C5=Herdr Agent Icons Max"
      ];
    };
  };

  # Home Manager validates the config with `ghostty +validate-config` when it changes, and
  # `theme = "dankcolors"` must exist at that point. DMS writes that file through matugen only
  # once the shell has run, so on a fresh home the validation fails and takes
  # home-manager-<user>.service down with it. Seed a placeholder; DMS replaces it later. An
  # existing file or symlink is never touched.
  home.activation.ghosttyThemeSeed = lib.hm.dag.entryBetween [ "onFilesChange" ] [ "writeBoundary" ] ''
    theme="${config.xdg.configHome}/ghostty/themes/dankcolors"
    if [[ ! -e "$theme" && ! -L "$theme" ]]; then
      run install -Dm644 ${pkgs.writeText "dankcolors-seed" ''
        background = #1e1e2e
        foreground = #cdd6f4
      ''} "$theme"
    fi
  '';
}
