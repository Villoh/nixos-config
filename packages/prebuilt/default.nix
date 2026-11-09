# TEMPORARY: upstream's prebuilt Linux releases of apps that otherwise compile from source here
# (flake inputs with nixpkgs.follows, or nixpkgs packages missing from cache.nixos.org).
# Drop this folder once a binary cache serves the source builds; each module line that uses
# one of these carries a "PENDING: cache" comment next to the original source-built line.
# Spread into packages/default.nix, so the names stay flat (a nested set would not be a
# valid `packages.<system>` output).
pkgs: {
  arca-bin = pkgs.callPackage ./arca/package.nix { };
  handy-bin = pkgs.callPackage ./handy/package.nix { };
  hex-bin = pkgs.callPackage ./hex/package.nix { };
  kopuz-bin = pkgs.callPackage ./kopuz/package.nix { };
  serein-bin = pkgs.callPackage ./serein/package.nix { };
  sheprd-bin = pkgs.callPackage ./sheprd/package.nix { };
  strata-bin = pkgs.callPackage ./strata/package.nix { };
  wealthfolio-bin = pkgs.callPackage ./wealthfolio/package.nix { };
  workmux-bin = pkgs.callPackage ./workmux/package.nix { };
  yapfast-bin = pkgs.callPackage ./yapfast/package.nix { };
  zapfast-bin = pkgs.callPackage ./zapfast/package.nix { };
}
