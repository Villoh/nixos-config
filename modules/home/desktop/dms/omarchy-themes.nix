{
  inputs,
  lib,
  pkgs,
  ...
}:

# Omarchy's themes as dmsProfiles looks: DMS theme.json files generated from each
# colors.toml, plus the wallpapers. Profiles themselves are DMS runtime state, so
# `omarchy-dms sync` creates them, run by the user service below on each login (it only
# adds what is missing). `omarchy-dms install` adds community themes
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
          name = "dms/themes/omarchy-${n}/${f}";
          value.source = "${dmsThemes}/omarchy-${n}/${f}";
        })
        [
          "theme.json"
          "preview-dark.svg"
          "preview-light.svg"
        ]
    ) names
  );

  # `recursive`: a real folder holding links to the pictures, not a link to the read-only
  # store folder, so it stays writable (the Wallhaven carousel downloads into the folder of
  # the active profile). find -L, Qt and omarchy-dms read the links as files.
  home.file = lib.genAttrs (map (n: "Pictures/Wallpapers/omarchy/${n}") names) (path: {
    source = "${wallpapers}/${baseNameOf path}";
    recursive = true;
  });

  # Creates the profiles on a fresh install. `sync` skips the ones that exist, so it is
  # safe on every login. It needs DMS and the dmsProfiles plugin answering on IPC, which
  # can lag behind dms.service starting: retry until it does.
  systemd.user.services.omarchy-dms-sync = {
    Unit = {
      Description = "Create the dmsProfiles profiles for Omarchy's themes";
      After = [ "dms.service" ];
      Wants = [ "dms.service" ];
      StartLimitIntervalSec = 300;
      StartLimitBurst = 10; # gives up after ~2.5 min instead of retrying forever
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe omarchy-dms} sync";
      Environment = [ "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = [ omarchy-dms ];
}
