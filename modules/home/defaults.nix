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
        "x-scheme-handler/http" = [ "zen.desktop" ];
        "x-scheme-handler/https" = [ "zen.desktop" ];
        "x-scheme-handler/chrome" = [ "zen.desktop" ];
        "text/html" = [ "zen.desktop" ];
        "application/x-extension-htm" = [ "zen.desktop" ];
        "application/x-extension-html" = [ "zen.desktop" ];
        "application/x-extension-shtml" = [ "zen.desktop" ];
        "application/xhtml+xml" = [ "zen.desktop" ];
        "application/x-extension-xhtml" = [ "zen.desktop" ];
        "application/x-extension-xht" = [ "zen.desktop" ];
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
