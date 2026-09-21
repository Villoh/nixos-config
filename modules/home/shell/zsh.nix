{ ... }:

{
  home-manager.users.mikel = {
    programs.zsh = {
      enable = true;
      dotDir = "/home/mikel/.config/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''
        [[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
      '';

      oh-my-zsh = {
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

    programs.zoxide.enable = true;

    programs.starship.enable = true;
  };
}
