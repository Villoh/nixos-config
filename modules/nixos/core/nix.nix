{ inputs, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Upstream CI caches for sonora, kopuz and handy. A flake input's nixConfig is ignored, so
  # they are trusted here; without them these three compile from source.
  nix.settings = {
    extra-substituters = [
      "https://sonora.cachix.org"
      "https://kopuz.cachix.org"
      "https://handy-computer.cachix.org"
    ];
    extra-trusted-public-keys = [
      "sonora.cachix.org-1:qbPeDsvZPbwUWHpQS5Oe0bjz5oHAVscHem+MCzwrc9Q="
      "kopuz.cachix.org-1:J2X3AnAYhKTJW5S3aCLoA1ckonQXVNZMQvhZA0YAufw="
      "handy-computer.cachix.org-1:Sihzctn6DC0CJM5QeL+9nBEL3CL8c33m777C+eIv748="
    ];
  };

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
      # Handy from its own flake (cached by handy-computer.cachix.org): 0.10 already ships the
      # WEBKIT_DMABUF_RENDERER_FORCE_SHM fix that nixpkgs' 0.9.x needed a patch for.
      handy = inputs.handy.packages.${prev.stdenv.hostPlatform.system}.default;
      # PENDING: cache. hex is the prebuilt release (packages/prebuilt) meanwhile; the source
      # build below is kept for when a binary cache serves it.
      hex = final.hex-bin;
      # Upstream's Russian i18n test fails on a missing macOS string at this rev; skip checks.
      # hex = inputs.hex.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
      #   doCheck = false;
      # });
    })
  ];
}
