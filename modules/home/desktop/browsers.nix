{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Defaults only: prefs.js/about:config in the profile still override them.
  zenPrefs = {
    # Unload tabs inactive for >1h, only under real memory pressure. Do NOT set
    # browser.low_commit_space_threshold_percent to 100: Linux then polls and
    # runs the tab unloader on the main thread every second (typing stutter).
    "browser.tabs.unloadOnLowMemory" = true;
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
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
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
    pkgs.brave-origin
    inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium
    zen-browser
  ];
}
