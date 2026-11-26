{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

# Glass looks that follow the active dmsProfiles profile (profiles are DMS runtime state):
#   liquid-glass-frame* -> connected frame with hyprglass Liquid Glass on it and on every DMS
#                    surface, plain hyprglass blur behind apps
#   liquid-*  -> standard bar as a liquidGlassBar capsule (plugin, ./plugins.nix), hyprglass
#                Liquid Glass on the other DMS surfaces, plain hyprglass blur behind apps
#   frosted-* -> connected frame with Hyprland's blur, plain hyprglass blur behind apps
#   others    -> opaque apps, no hyprglass (the seeded `dynamic` base profile included)
# In both glass modes apps get a light, uniform translucency. Their blur comes from
# hyprglass, not Hyprland: GTK4 apps (Ghostty, Strata) announce an empty blur region
# through ext-background-effect-v1, and Hyprland then never blurs behind them.
# dmsProfiles runs `dms-glass` while switching (its "apply command", set in
# plugin_settings.json); it turns liquidGlassBar on or off, stores the mode and reloads
# Hyprland, whose config reads it.
# The file outlives a logout, so Hyprland starts in the mode of the last profile.
#
# The profiles are seeded here when missing. A seed holds only the look it is about
# (dynamic colors, blur, transparency, bar layout), with no wallpaper or fonts: applying it
# keeps those as they are. Once active, DMS autosave fills it with the whole look, wallpaper
# included. Dynamic colors only: the glass tint comes from the wallpaper, like macOS vibrancy
# (a fixed palette also recolors terminals and GTK apps).
let
  profilesDir = "${config.xdg.configHome}/dms/profiles";
  # Own wallpaper folder for the dynamic-color profiles (glass and base): the picker opens here
  # and the Wallhaven carousel downloads here, instead of into the folder of whatever wallpaper
  # was on before.
  wallpaperFolder = "${config.home.homeDirectory}/Pictures/Wallpapers/dynamic";

  glass = {
    blurEnabled = true;
    blurForegroundLayers = true;
    frameBlurEnabled = true;
    # Hyprland blur passes 3, size 9 (DMS's default is 2 x 8): frosted, not just softened.
    blurStrength = 120;
  };
  # Frosted: DMS draws a fairly solid tint over Hyprland's blur.
  frosted = glass // {
    popupTransparency = 0.65;
    foregroundLayerTransparency = 0.55;
    floatingWindowTransparency = 0.75;
    floatingWindowForegroundTransparency = 0.55;
  };
  # Liquid: a light tint, hyprglass draws the glass behind it.
  liquid = glass // {
    popupTransparency = 0.35;
    foregroundLayerTransparency = 0.4;
    floatingWindowTransparency = 0.5;
    floatingWindowForegroundTransparency = 0.4;
  };
  dynamic = {
    currentThemeCategory = "dynamic";
    currentThemeName = "dynamic";
  };

  # Bar layout per profile (keys of the first bar, id "default").
  frameBar = {
    settings = {
      frameEnabled = true;
      frameMode = "connected";
    };
    bar = {
      followInterfaceStyle = true;
      noBackground = false;
      spacing = 4;
    };
  };
  # liquidGlassBar's setup: a standard bar with nothing of its own drawn, the plugin draws the
  # glass underneath. noBackground rather than widget opacity 0: transparent widget pills
  # still ask Hyprland for blur, which then blurs the glass under each widget.
  liquidBar = {
    settings.frameEnabled = false;
    bar = {
      followInterfaceStyle = false;
      transparency = 0;
      noBackground = true;
      borderEnabled = false;
      gothCornersEnabled = false;
      spacing = 8;
    };
  };

  seed =
    name: settings: layout:
    pkgs.writeText "dms-profile.json" (
      builtins.toJSON {
        inherit name;
        created = "2026-11-24T00:00:00";
        wallpaper = "";
        inherit wallpaperFolder;
        dms = {
          configVersion = 42; # older versions are migrated by the plugin
          settings = settings // layout.settings;
          # Only the first bar: extra bars would be switched off.
          bars.default = layout.bar;
          session.isLightMode = false;
        };
      }
    );
  seeds = {
    # Base look: dynamic colors, opaque, no blur. dms-glass maps it to mode off.
    dynamic = seed "Dynamic" (
      dynamic
      // {
        blurEnabled = false;
        popupTransparency = 1;
      }
    ) frameBar;
    frosted-glass = seed "Frosted Glass" (frosted // dynamic) frameBar;
    liquid-glass = seed "Liquid Glass" (liquid // dynamic) liquidBar;
    liquid-glass-frame = seed "Liquid Glass Frame" (liquid // dynamic) frameBar;
  };

  dms-glass = pkgs.writeShellApplication {
    name = "dms-glass";
    runtimeInputs = [
      osConfig.programs.hyprland.package
      osConfig.programs.dux-shell.package
      pkgs.gawk
      pkgs.jq
      pkgs.util-linux
    ];
    text = ''
      # `dms-glass fix`, run by display.lua after monitor changes: a monitor that came back
      # (input switch, lid, reload) can stay without glass under its bar, as DMS rebuilds the
      # bar after liquidGlassBar looked. Reload the plugin if a bar lacks its capsule.
      if [ "''${1:-}" = fix ]; then
        # Only the liquidGlassBar capsule needs fixing: with the plugin off (frosted and frame
        # profiles have no dms:bar layer) there is nothing to wait for.
        jq -e '.liquidGlassBar.enabled' "''${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json" > /dev/null 2>&1 || exit 0
        exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/dms-glass-fix.lock"
        flock -n 9 || exit 0
        # DMS rebuilds its layer surfaces a few seconds after the change (~3 s measured): wait
        # for a bar on every active monitor (20 s cap, e.g. a monitor DMS gives no bar), then
        # let the glass settle.
        for ((i = 0; i < 40; i++)); do
          mons=$(hyprctl monitors | awk '/^Monitor/ { n++ } END { print n + 0 }')
          bars=$(hyprctl layers | awk '/^Monitor/ { m = $2 } /dms:bar/ { s[m] = 1 } END { for (k in s) n++; print n + 0 }')
          if [ "$mons" -gt 0 ] && [ "$bars" -ge "$mons" ]; then break; fi
          sleep 0.5
        done
        sleep 2
        hyprctl layers | awk '
          /^Monitor/ { m = $2 }
          /dms:liquid-glass/ { glass[m] = 1; any = 1 }
          /dms:bar/ { bar[m] = 1 }
          END { for (m in bar) if (any && !glass[m]) exit 1 }' && exit 0
        dms ipc call plugins disable liquidGlassBar >/dev/null || true
        sleep 1
        dms ipc call plugins enable liquidGlassBar >/dev/null || true
        exit 0
      fi

      slug=''${DMS_PROFILE_SLUG:-''${1:-}}
      plugin=disable
      case $slug in
        liquid-glass-frame*) mode=liquid ;;
        liquid-*) mode=liquid plugin=enable ;;
        frosted-*) mode=frosted ;;
        *) mode=off ;;
      esac
      # Every time, not only on a mode change: the plugin state lives in plugin_settings.json.
      dms ipc call plugins "$plugin" liquidGlassBar >/dev/null || true
      file=''${XDG_STATE_HOME:-$HOME/.local/state}/dms-glass/mode
      [ "$(cat "$file" 2>/dev/null)" = "$mode" ] && exit 0
      mkdir -p "$(dirname "$file")"
      printf '%s\n' "$mode" >"$file"
      hyprctl reload >/dev/null
    '';
  };
in
lib.mkIf osConfig.programs.dux-shell.enable {
  home.packages = [ dms-glass ];

  # Only missing profiles: an existing one is the user's, autosaved by DMS. `refresh` lets a
  # running DMS list them; at login the plugin reads the folder itself.
  home.activation.dmsGlassProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg wallpaperFolder}
    ${lib.concatStrings (
      lib.mapAttrsToList (slug: file: ''
        if [ ! -e ${lib.escapeShellArg "${profilesDir}/${slug}/profile.json"} ]; then
          run install -Dm644 ${file} ${lib.escapeShellArg "${profilesDir}/${slug}/profile.json"}
        fi
      '') seeds
    )}
    ${lib.getExe' osConfig.programs.dux-shell.package "dms"} ipc call profiles refresh >/dev/null 2>&1 || true
  '';

  wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprglass ];
    extraConfig = lib.mkAfter ''
      -- Glass mode of the active DMS profile, written by dms-glass (modules/home/desktop/dms/profiles.nix).
      do
        local f = io.open((os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/dms-glass/mode")
        local mode = f and f:read("l") or "off"
        if f then f:close() end

        if mode ~= "off" then
          -- Light translucency, so the blur or the glass shows through apps. Fullscreen stays opaque.
          hl.config({ decoration = { active_opacity = 0.93, inactive_opacity = 0.88 } })
          hl.window_rule({ match = { content = "game" }, opaque = true })
          hl.window_rule({ match = { content = "video" }, opaque = true })
          hl.window_rule({ match = { class = "^steam_app_" }, opaque = true })
        end

        if hl.plugin.hyprglass then
          local liquid = mode == "liquid"
          local hg = hl.plugin.hyprglass
          -- Frosted: the blur alone, without refraction, edges, highlights or tint.
          hg.preset("frosted", {
            refraction_strength = 0,
            chromatic_aberration = 0,
            fresnel_strength = 0,
            specular_strength = 0,
            lens_distortion = 0,
            edge_thickness = 0,
            tint_color = 0x00000000,
          })
          -- Liquid, after Apple's menus and control centre: softly frosted glass bent only along a
          -- narrow rim (flat centre), a light rim reflection and a trace of colour fringe. On DMS
          -- only: Apple keeps Liquid Glass to bars, menus and controls, so app windows get the
          -- frosted blur.
          hg.preset("liquid", {
            inherits = "pomme",
            blur_strength = 1.5,
            edge_height = 30,
            edge_thickness_px = 20,
            refraction_strength = 0.6,
            chromatic_aberration = 0.15,
            fresnel_reflection = 0.3,
          })
          -- region: glass exactly where DMS asks for blur (its rounded surfaces), so the
          -- content inside (thumbnails, cards) gets no edges of its own.
          hg.config({
            enabled = mode ~= "off",
            default_preset = "frosted",
            default_theme = "dark",
            layers = {
              enabled = liquid,
              preset = "liquid",
              mask_mode = "region",
              mask_threshold = 0.15,
              popups = { enabled = liquid },
            },
          })
          -- Except the connected frame: a full-screen layer whose blur request covers the whole
          -- desktop. contour follows what it draws (bar, ring, popout bodies); the threshold
          -- keeps its soft shadows out. Listing a layer whitelists, so "*" keeps the rest.
          hg.layer("*")
          hg.layer("dms:frame", { mask_mode = "contour" })
          -- liquidGlassBar's capsule and the bar over it: glass there darkens the capsule.
          hg.layer("dms:liquid-glass", { exclude = true })
          hg.layer("dms:bar", { exclude = true })
        end
      end
    '';
  };
}
