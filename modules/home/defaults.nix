{ ... }:

{
  home-manager.users.mikel = {
    home.sessionVariables = {
      EDITOR = "zeditor";
      VISUAL = "zeditor";
      BROWSER = "zen";
      TERMINAL = "ghostty";
      EXPLORER = "dolphin";
      PAGER = "less";
      FILE_MANAGER = "dolphin";
    };

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
        "image/*" = [ "imv.desktop" ];
        "video/*" = [ "mpv.desktop" ];
        "audio/*" = [ "mpv.desktop" ];
        "x-scheme-handler/http" = [ "zen.desktop" ];
        "x-scheme-handler/https" = [ "zen.desktop" ];
        "x-scheme-handler/chrome" = [ "zen.desktop" ];
        "text/html" = [ "zen.desktop" ];
        "application/xhtml+xml" = [ "zen.desktop" ];
        "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
        "x-scheme-handler/about" = [ "zen.desktop" ];
        "x-scheme-handler/unknown" = [ "zen.desktop" ];
      };

      associations.added = {
        "x-scheme-handler/http" = [ "zen.desktop" ];
        "x-scheme-handler/https" = [ "zen.desktop" ];
        "text/html" = [ "zen.desktop" ];
        "x-scheme-handler/chrome" = [ "zen.desktop" ];
      };
    };
  };
}
