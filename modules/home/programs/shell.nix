{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      # Starship owns the prompt; Oh My Zsh only provides the plugins.
      theme = "";
      plugins = [
        "git"
        "sudo"
        "history-substring-search"
        "colored-man-pages"
      ];
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
