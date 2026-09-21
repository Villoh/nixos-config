{ ... }:

{
  home-manager.users.mikel = {
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/pnpm/bin"
    ];

    home.sessionVariables = {
      EDITOR = "zeditor";
      VISUAL = "zeditor";
      BROWSER = "zen";
      TERMINAL = "ghostty";
      EXPLORER = "dolphin";
      PAGER = "less";
      FILE_MANAGER = "dolphin";
    };
  };
}
