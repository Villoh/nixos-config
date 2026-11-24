{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  mkEngine = alias: template: {
    definedAliases = [ alias ];
    urls = [ { inherit template; } ];
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  # Known issue (investigated 2026-11-24, Hyprland 0.57.2, Zen 1.24.3b, eGPU RTX 3080): a large
  # Zen window on native Wayland lags on every focus change (switching workspace or monitor, or
  # opening another window on the same workspace), tiled or floating. At 1/4 of the screen it
  # does not lag; under XWayland (MOZ_ENABLE_WAYLAND=0, layout.css.devPixelsPerPx = 1.5 for the
  # scale) it does not lag; Brave and Ladybird do not lag. Not worked around here: XWayland
  # loses native fractional scaling.
  # Disabling Hyprland animations fixes only the same-monitor workspace switch.
  # On a focus change Hyprland sends xdg_toplevel.configure with the same size and only the
  # activated state toggled, and Zen answers with a full repaint; but that alone does not
  # explain it: a nested Hyprland with a clean config got the same configure and no repaint.
  # Not reproduced yet on a real DRM session with a clean config.
  # Upstream, open and without a fix: hyprwm/Hyprland discussion #16409 (Firefox relayouts on
  # every focus change); related: #14095 (4K 160 Hz, Zen/Librewolf), #15390 (fractional scale).
  # Not about this: #14440 (spring animations, fixed in hyprutils #110).
  # Ruled out by measurement or by hand: the profile, extensions, user.js, userChrome, DMS,
  # software WebRender and its compositor, widget.wayland.* prefs, dmabuf, Gecko's Wayland proxy,
  # wp_fifo/wp_commit_timing, GPU clocks, PCIe traffic, hardware cursor, 10-bit/160 Hz on DP-3,
  # blur, shadows, nvidia_anti_flicker and new_render_scheduling.
  # Retest after a Hyprland or Zen update, and remove this note if it is fixed.

  # Upstream uses Exec=zen-beta, which Claude's reduced PATH cannot resolve.
  # Keep its desktop entry and actions, but point all of them at the configured wrapper.
  # Remove when zen-browser-flake ships absolute Exec paths.
  xdg.dataFile."applications/zen-beta.desktop".source =
    pkgs.runCommand "zen-beta-desktop-absolute-exec" { }
      ''
        cp ${config.programs.zen-browser.package}/share/applications/zen-beta.desktop "$out"
        substituteInPlace "$out" \
          --replace-fail 'Exec=zen-beta ' 'Exec=${lib.getExe config.programs.zen-browser.package} '
      '';

  # DMS writes ~/.config/dms/zen.css but never links it into the profile. Out-of-store, so
  # DMS keeps regenerating the target without a rebuild.
  xdg.configFile."zen/35l08yb0.Default Profile/chrome/userChrome.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/dms/zen.css";

  programs.zen-browser = {
    enable = true;

    # Locked, enforced by policies.json. The package already registers the system CA store.
    # Not DisableFirefoxAccounts: it would break Firefox Sync (IronFox on the phone).
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      NoDefaultBookmarks = true;
    };

    # The profile predates Home Manager: pin its directory so profiles.ini keeps pointing at it
    # (sessions and extensions live there). Spaces, pins, containers, bookmarks and extensions
    # stay out of Nix on purpose: they hold state Zen edits at runtime. userChrome.css is the
    # symlink to the DMS/Matugen output declared above.
    profiles."Default Profile" = {
      id = 0;
      path = "35l08yb0.Default Profile";
      isDefault = true;

      # force: Zen replaces the symlink to search.json.mozlz4 on every start, so without it the
      # declared engines are lost. It also drops engines added from the UI; declare them here.
      search = {
        force = true;
        default = "brave";
        engines = {
          # Built-in engines the profile already had; declaring them keeps them listed.
          google = { };
          bing = { };
          ddg = { };
          ecosia = { };
          perplexity = { };
          qwant = { };
          wikipedia = { };

          # Custom engines the profile already had.
          startpage = {
            name = "Startpage";
            definedAliases = [ "@startpage" ];
            urls = [
              { template = "https://www.startpage.com/sp/search?query={searchTerms}"; }
              {
                template = "https://www.startpage.com/osuggestions?q={searchTerms}";
                type = "application/x-suggestions+json";
              }
            ];
          };
          brave = {
            name = "Search Brave";
            definedAliases = [ "@brave" ];
            urls = [
              { template = "https://search.brave.com/search?q={searchTerms}"; }
              {
                template = "https://search.brave.com/api/suggest?q={searchTerms}";
                type = "application/x-suggestions+json";
              }
            ];
          };

          nix-packages =
            mkEngine "@np" "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"
            // {
              name = "NixOS Packages";
              icon = nixIcon;
            };
          nix-options =
            mkEngine "@no" "https://search.nixos.org/options?channel=unstable&query={searchTerms}"
            // {
              name = "NixOS Options";
              icon = nixIcon;
            };
          home-manager-options =
            mkEngine "@hm" "https://home-manager-options.extranix.com/?query={searchTerms}&release=master"
            // {
              name = "Home Manager Options";
              icon = nixIcon;
            };
          nixos-wiki = mkEngine "@nw" "https://wiki.nixos.org/w/index.php?search={searchTerms}" // {
            name = "NixOS Wiki";
            icon = nixIcon;
          };
          github = mkEngine "@gh" "https://github.com/search?q={searchTerms}" // {
            name = "GitHub";
          };
          youtube = mkEngine "@yt" "https://www.youtube.com/results?search_query={searchTerms}" // {
            name = "YouTube";
          };
        };
      };

      # Written to user.js: re-applied on every start, a change in about:config lasts one session.
      settings = {
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
        # Off by default in Zen: without it chrome/userChrome.css (DMS/Matugen colours) is ignored.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "full-screen-api.warning.timeout" = 0;
        "browser.download.alwaysOpenPanel" = false;
        # Ctrl+W on a pinned tab closes it instead of switching (Zen default: "switch").
        "zen.pinned-tab-manager.close-shortcut-behavior" = "close";
        "zen.folders.owned-tabs-in-folder" = true;
        # WebGPU is not enabled by default on Linux Firefox.
        "dom.webgpu.enabled" = true;

        # Privacy. FPP instead of RFP, as IronFox does: RFP is all-or-nothing and breaks sites.
        "browser.contentblocking.category" = "strict";
        "privacy.fingerprintingProtection" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.query_stripping.enabled" = true;
        "privacy.query_stripping.enabled.pbmode" = true;
        "network.cookie.cookieBehavior" = 5;
        "network.IDN_show_punycode" = true;
        "browser.send_pings" = false;
        "beacon.enabled" = false;
        "dom.battery.enabled" = false;
        "browser.discovery.enabled" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
      };
    };
  };
}
