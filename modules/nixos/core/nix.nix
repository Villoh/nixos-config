{ inputs, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # PENDING: cache. Fill in when the pipeline pushes to the private cache, then revert the
  # `-bin` swaps (see docs/maintenance/updates.md). Keep the key public; never commit the secret.
  # nix.settings = {
  #   extra-substituters = [ "https://<private-cache>" ];
  #   extra-trusted-public-keys = [ "<cache-name>:<public-key>" ];
  # };

  programs.nh.enable = true;
  environment.systemPackages = [
    inputs.nixup.packages.${pkgs.stdenv.hostPlatform.system}.default
    # `nixup update` edits the packages in packages/ with it; without it on PATH nixup falls
    # back to `nix run nixpkgs#nix-update`, which needs the network after every GC.
    pkgs.nix-update
  ];

  # Allow Pi's prebuilt Linux computer-use helper to run on NixOS.
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;

  # uv's standalone Pythons look for the CA bundle in /etc/ssl/cert.pem (NixOS has no such file),
  # so every HTTPS call from them fails with CERTIFICATE_VERIFY_FAILED.
  environment.etc."ssl/cert.pem".source = "/etc/ssl/certs/ca-bundle.crt";

  nixpkgs.overlays = [
    inputs.self.overlays.default
    (final: prev: {
      # PENDING: cache. handy and hex are the prebuilt releases (packages/prebuilt) meanwhile;
      # the source builds below are kept for when a binary cache serves them. The Handy patch
      # is not needed on 0.10, which ships the same fix.
      handy = final.handy-bin;
      hex = final.hex-bin;
      # Handy 0.9.6 forces WEBKIT_DISABLE_DMABUF_RENDERER=1, which makes WebKitGTK 2.54
      # draw only the damaged regions (overlay turns into a glitchy square). Use the
      # upstream fix (cjpais/Handy#2360) instead. Remove once nixpkgs ships Handy >= 0.10.
      # handy = prev.handy.overrideAttrs (old: {
      #   postPatch = (old.postPatch or "") + ''
      #     substituteInPlace src-tauri/src/main.rs \
      #       --replace-fail 'std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");' \
      #                      'std::env::set_var("WEBKIT_DMABUF_RENDERER_FORCE_SHM", "1");'
      #   '';
      #   preFixup = builtins.replaceStrings [ "--set WEBKIT_DISABLE_DMABUF_RENDERER 1" ] [
      #     "--set WEBKIT_DMABUF_RENDERER_FORCE_SHM 1"
      #   ] old.preFixup;
      # });
      # Upstream's Russian i18n test fails on a missing macOS string at this rev; skip checks.
      # hex = inputs.hex.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
      #   doCheck = false;
      # });
    })
  ];
}
