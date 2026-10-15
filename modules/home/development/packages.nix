{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Editor + LSP
    zed-editor
    nil
    nixd
    nixfmt
    nixpkgs-review
    qt6.qtdeclarative # qmlls, qmlformat, qmllint

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
    wrangler
    android-tools

    # Languages + toolchains
    rustup
    go
    gcc
    gnumake
    nodejs_24
    deno
    jdk
    maven
    tomcat9 # wannme-v2-admin: make admin TOMCAT_HOME=$(dirname $(dirname $(readlink -f $(which catalina.sh))))
    dotnet-sdk_10
    python3

    # Version/package managers
    aube
    mise
    uv
    pnpm
  ];
}
