{ pkgs, ... }:

{
  xdg.mimeApps = {
    enable = true;

    # Registers each package as default for every type its .desktop declares.
    # Wildcards (image/*, video/*) are ignored by xdg-mime, so list real types.
    defaultApplicationPackages = [
      pkgs.imv
      pkgs.mpv
    ];

    # imv-dir (opens the whole folder) sorts before imv, so it wins. To make plain
    # imv win, add `lib` to the args and merge explicit entries into
    # defaultApplications (explicit entries come first, packages are appended):
    #   lib.genAttrs
    #     (map (t: "image/${t}") [ "png" "jpeg" "gif" "bmp" "webp" "avif" "svg+xml" ])
    #     (_: [ "imv.desktop" ])
    #   // { ... }
    defaultApplications = {
      "inode/directory" = [ "io.github.lgse.Strata.desktop" ];
      # Strata browses trash:/// but its .desktop doesn't declare the scheme.
      "x-scheme-handler/trash" = [ "io.github.lgse.Strata.desktop" ];
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
      "x-scheme-handler/chrome" = [ "zen-beta.desktop" ];
      "text/html" = [ "zen-beta.desktop" ];
      "text/plain" = [ "dev.zed.Zed.desktop" ];
      "application/xhtml+xml" = [ "zen-beta.desktop" ];
      "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
      "x-scheme-handler/about" = [ "zen-beta.desktop" ];
      "x-scheme-handler/unknown" = [ "zen-beta.desktop" ];
    };

    associations.added = {
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
      "text/html" = [ "zen-beta.desktop" ];
      "x-scheme-handler/chrome" = [ "zen-beta.desktop" ];
    };
  };
}
