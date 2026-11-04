{ inputs, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nh.enable = true;
  environment.systemPackages = [ inputs.nixup.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Allow Pi's prebuilt Linux computer-use helper to run on NixOS.
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;

  # uv's standalone Pythons look for the CA bundle in /etc/ssl/cert.pem (NixOS has no such file),
  # so every HTTPS call from them fails with CERTIFICATE_VERIFY_FAILED.
  environment.etc."ssl/cert.pem".source = "/etc/ssl/certs/ca-bundle.crt";

  # Backport of NixOS/nixpkgs#569777 (canvas 3.1.0 fails on GCC 15+).
  # Remove once the PR lands in nixos-unstable.
  nixpkgs.overlays = [
    inputs.self.overlays.default
    (_final: prev: {
      # Handy 0.9.6 forces WEBKIT_DISABLE_DMABUF_RENDERER=1, which makes WebKitGTK 2.54
      # draw only the damaged regions (overlay turns into a glitchy square). Use the
      # upstream fix (cjpais/Handy#2360) instead. Remove once nixpkgs ships Handy >= 0.10.
      handy = prev.handy.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src-tauri/src/main.rs \
            --replace-fail 'std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");' \
                           'std::env::set_var("WEBKIT_DMABUF_RENDERER_FORCE_SHM", "1");'
        '';
        preFixup = builtins.replaceStrings [ "--set WEBKIT_DISABLE_DMABUF_RENDERER 1" ] [
          "--set WEBKIT_DMABUF_RENDERER_FORCE_SHM 1"
        ] old.preFixup;
      });
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
