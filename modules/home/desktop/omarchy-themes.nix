{
  inputs,
  lib,
  pkgs,
  ...
}:

# Omarchy's themes as dmsProfiles looks: DMS theme.json files generated from each
# colors.toml, plus the wallpapers. Profiles themselves are DMS runtime state, so
# `omarchy-dms sync` creates them once. `omarchy-dms install` adds community themes
# from omarchy.org/themes on demand, next to these (they are not part of the build).
let
  root = "${inputs.omarchy}/themes";
  names = lib.attrNames (
    lib.filterAttrs (n: t: t == "directory" && builtins.pathExists "${root}/${n}/colors.toml") (
      builtins.readDir root
    )
  );

  # The published CLI, told where Omarchy's own themes live.
  omarchy-dms = pkgs.symlinkJoin {
    name = "omarchy-dms";
    paths = [ inputs.omarchy-dms.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/omarchy-dms --set OMARCHY_THEMES ${root}";
    meta.mainProgram = "omarchy-dms";
  };

  dmsThemes = pkgs.runCommand "omarchy-dms-themes" { nativeBuildInputs = [ omarchy-dms ]; } ''
    for n in ${lib.escapeShellArgs names}; do
      omarchy-dms render "${root}/$n/colors.toml" "$n" "$out/omarchy-$n"
    done
  '';

  # Still images only (no intro videos, no ~700-byte placeholders). Real copies,
  # not symlinks, so the dmsProfiles wallpaper picker lists them.
  wallpapers = pkgs.runCommand "omarchy-wallpapers" { } ''
    for dir in ${root}/*/backgrounds; do
      t=$(basename "$(dirname "$dir")")
      mkdir -p "$out/$t"
      find "$dir" -maxdepth 1 -type f -size +2k \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -exec cp {} "$out/$t/" \;
    done
  '';
in
{
  # Link the files, not the theme folders: DMS lists installed themes with a
  # directory scan that skips symlinks, so a linked folder never shows in
  # Settings > Theme > Browse. This also keeps the parent writable for
  # `omarchy-dms install`, like the wallpaper folder below.
  xdg.configFile = lib.listToAttrs (
    lib.concatMap (
      n:
      map
        (f: {
          name = "DankMaterialShell/themes/omarchy-${n}/${f}";
          value.source = "${dmsThemes}/omarchy-${n}/${f}";
        })
        [
          "theme.json"
          "preview-dark.svg"
          "preview-light.svg"
        ]
    ) names
  );

  home.file = lib.genAttrs (map (n: "Pictures/Wallpapers/omarchy/${n}") names) (path: {
    source = "${wallpapers}/${baseNameOf path}";
  });

  home.packages = [ omarchy-dms ];
}
