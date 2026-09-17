{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    interactiveShellInit = ''
      if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi
    '';

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
