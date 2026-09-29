{ ... }:

{
  imports = [
    ./packages.nix
    ./cliproxyapi.nix
    ./neovim.nix
    ./codex.nix
    ./tunnel-agent.nix
  ];
}
