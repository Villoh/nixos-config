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
    package = osConfig.programs.dms-shell.package;
    quickshell.package = osConfig.programs.dms-shell.quickshell.package;
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
        src = lib.mkForce (pkgs.callPackage ./dms-bitwarden.nix { });
      };
      dankKDEConnect.enable = true;
      quickCapture.enable = true;
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
    };
  };

  # Security/shell/media already supply bw, jq, wl-clipboard and capture tools.
  # KDE Connect (rather than Valent), Docker, Tailscale and Nix are system services/tools.
  home.packages = [
    pkgs.curl
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
