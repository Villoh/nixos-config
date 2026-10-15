{ ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nh.enable = true;

  # Allow Pi's prebuilt Linux computer-use helper to run on NixOS.
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Backport of NixOS/nixpkgs#569777 (canvas 3.1.0 fails on GCC 15+).
  # Remove once the PR lands in nixos-unstable.
  nixpkgs.overlays = [
    (_final: prev: {
      filen-desktop = prev.filen-desktop.overrideAttrs (old: {
        npmRebuildFlags = (old.npmRebuildFlags or [ ]) ++ [ "--ignore-scripts" ];
        preBuild = (old.preBuild or "") + ''
          substituteInPlace node_modules/canvas/src/CharData.h \
            --replace-fail '#pragma once' '#pragma once
          #include <cstdint>'

          npm rebuild
        '';
      });
    })
  ];
}
