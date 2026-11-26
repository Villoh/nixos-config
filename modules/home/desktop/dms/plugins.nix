{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms-plugin-registry.homeModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    # Reuse the host's patched shell and runtime; do not start a second service.
    package = osConfig.programs.dux-shell.package;
    quickshell.package = osConfig.programs.dux-shell.quickshell.package;
    systemd.enable = false;

    # DMS/chezmoi retain settings ownership; HM only deploys plugin code.
    managePluginSettings = false;

    # Shared runtime dependencies come from NixOS, not this plugin selection.
    enableVPN = false;
    enableDynamicTheming = false;
    enableAudioWavelength = false;
    enableCalendarEvents = false;

    plugins = {
      bitwarden = {
        enable = true;
        # Pinned on purpose (1.11.6-dms.2, audited 2026-10-14); registry bumps are ignored.
        src = lib.mkForce (pkgs.callPackage ./bitwarden.nix { });
      };
      dankKDEConnect.enable = true;
      quickCapture.enable = true;
      screenCaptureToolbar.enable = true;
      dockerManager.enable = true;
      dankscale.enable = true;
      dmsProfiles = {
        enable = true;
        # Fork with the wallpaper picker and the per-profile wallpaper folder (upstream
        # PR #2), tracked through the dms-profiles flake input.
        src = lib.mkForce inputs.dms-profiles;
      };
      cliproxyQuota.enable = true;
      commandRunner.enable = true;
      nixPackageRunner.enable = true;
      emojiLauncher.enable = true;
      emojiPicker.enable = true;
      mise.enable = true;
      calculator.enable = true;
      # Audited 2026-11-13: local credentials only go to their provider's API.
      aiOverviewControl.enable = true;
      wallhavenCarousel.enable = true;
      orbitBluetooth.enable = true;
      # Local: menu (overlay, window or dash tab) for `game-capture` (../game-capture.nix).
      gameCapture = {
        enable = true;
        src = ./game-capture;
      };
      # Not in the registry. Installed only: dms-glass (./profiles.nix) turns it on for the
      # liquid-* profiles and off for the rest.
      liquidGlassBar = {
        enable = true;
        src = pkgs.fetchFromGitHub {
          owner = "hua0512";
          repo = "dms-liquid-glass-bar";
          rev = "7ee1391411fd3f0cbc2a5e980d28df57742f4bd5"; # 0.1.1
          hash = "sha256-VWZfacG8lV9BD/QxwBu8I02sK7WicQgXL/HIqF/qix4=";
        };
      };
    };
  };

  # Security/shell/media already supply bw, jq, wl-clipboard and capture tools.
  # KDE Connect (rather than Valent), Docker, Tailscale and Nix are system services/tools.
}
