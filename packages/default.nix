# Packages that are not in nixpkgs (or run ahead of it). Every one carries
# `passthru.updateScript`, so `nix-update --flake <name>` bumps version and hashes,
# except herdr-core and herdr-app, which upstream hosts outside GitHub.
# Exposed as `packages.<system>.*` and, through `overlays.default`, as `pkgs.<name>`.
pkgs: rec {
  flectar-mail = pkgs.callPackage ./flectar-mail/package.nix { };
  tunnel-agent = pkgs.callPackage ./tunnel-agent/package.nix { };
  # Herdr App under evaluation: a prebuilt release, so nothing is compiled.
  herdr-core = pkgs.callPackage ./herdr-core/package.nix { };
  herdr-app = pkgs.callPackage ./herdr-app/package.nix { inherit herdr-core; };
  # Shadows nixpkgs' wealthfolio on purpose: nixpkgs runs behind upstream.
  wealthfolio = pkgs.callPackage ./wealthfolio/package.nix { };
}
