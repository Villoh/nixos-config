{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Defaults only: prefs.js/about:config in the profile still override them.
  zenPrefs = {
    # Unload tabs inactive for >1h under memory pressure. Threshold 100 makes
    # Firefox treat memory as always low, so only the inactivity time filters.
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.low_commit_space_threshold_percent" = 100;
    "browser.tabs.min_inactive_duration_before_unload" = 3600000;
    # Dim tabs unloaded automatically so they are visible in the tab bar.
    "browser.tabs.fadeOutUnloadedTabs" = true;
    # Fewer session-store disk writes (default 15s).
    "browser.sessionstore.interval" = 60000;
    "browser.quitShortcut.disabled" = true;
    "full-screen-api.warning.timeout" = 0;
    "browser.download.alwaysOpenPanel" = false;
    # Ctrl+W on a pinned tab closes it instead of switching (Zen default: "switch").
    "zen.pinned-tab-manager.close-shortcut-behavior" = "close";
    "zen.folders.owned-tabs-in-folder" = true;
    # WebGPU is not enabled by default on Linux Firefox.
    "dom.webgpu.enabled" = true;
  };

  zen-browser =
    pkgs.wrapFirefox
      (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped.overrideAttrs
        (old: {
          passthru = (old.passthru or { }) // {
            # wrapFirefox checks withFFmpeg; the flake's ffmpegSupport flag is ignored.
            withFFmpeg = true;
          };
        })
      )
      {
        pname = "zen-browser";
        extraPrefs = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "defaultPref(${builtins.toJSON name}, ${builtins.toJSON value});"
          ) zenPrefs
        );
      };
in
{
  home.packages = [
    pkgs.brave
    inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium
    zen-browser
  ];
}
