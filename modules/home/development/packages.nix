{ inputs, pkgs, ... }:

{
  home-manager.users.mikel = {
    home.packages = with pkgs; [
      # Editor + LSP
      zed-editor
      nil
      nixd
      nixfmt

      # LSP + linters (replace pnpm/uv globals)
      vtsls
      typescript
      typescript-language-server
      bash-language-server
      vscode-langservers-extracted
      eslint
      oxlint
      basedpyright
      pyright
      zuban
      pre-commit

      # Databases
      mysql84.client
      usql

      # AI agents
      claude-code
      codex
      pi-coding-agent
      devin-cli
      devin-desktop
      herdr
      omp
      happy-coder
      openspec
      spec-kit
      graphify
      moji

      # CLI tools
      acli
      nchat
      agent-browser
      ctx7
      defuddle
      devcontainer
      filen-cli
      wrangler

      # Languages + toolchains
      rustup
      go
      gcc
      gnumake
      nodejs_24
      deno
      jdk
      maven
      dotnet-sdk_10
      python3

      # Version/package managers
      mise
      uv
      pnpm
    ];
  };
}
