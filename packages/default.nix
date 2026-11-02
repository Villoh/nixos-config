# Packages that are not in nixpkgs (or run ahead of it). Every one carries
# `passthru.updateScript`, so `nix-update --flake <name>` bumps version and hashes.
# Exposed as `packages.<system>.*` and, through `overlays.default`, as `pkgs.<name>`.
pkgs: {
  flectar-mail = pkgs.callPackage ./flectar-mail/package.nix { };
  padpoll = pkgs.callPackage ./padpoll/package.nix { };
  selawik = pkgs.callPackage ./selawik/package.nix { };
  tunnel-agent = pkgs.callPackage ./tunnel-agent/package.nix { };
  # Shadows nixpkgs' wealthfolio on purpose: nixpkgs runs behind upstream.
  wealthfolio = pkgs.callPackage ./wealthfolio/package.nix { };
}
