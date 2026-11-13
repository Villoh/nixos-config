{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  enable = osConfig.programs.noctalia.enable;

  # Directory names inside each plugin repo; the plugin ids come from their plugin.toml.
  official = [
    "bitwarden" # bw serve vault in the launcher (/bw)
    "screen_recorder" # gpu-screen-recorder: recording and replay buffer
  ];
  community = [
    "audio-switcher" # Cycle audio outputs/inputs from a keybind (../hyprland/shell-binds.nix)
    "emoji-picker" # Emoji and symbol picker (../hyprland/shell-binds.nix)
    "screen-toolkit" # Color picker, OCR, QR, annotate (../hyprland/shell-binds.nix); recording stays with screen_recorder
    "herdr" # Herdr sessions and coding agents in the bar
    "mini-docker" # Docker containers
    "nix-search" # nixpkgs / NixOS / Home Manager search in the launcher (nix-search-tv)
    "phone-connect" # KDE Connect (NixOS enables it)
    "tailscale" # Tailscale peers and exit nodes (NixOS enables it)
    "theme-switcher" # Saved themes carousel (SUPER+CTRL+T, ../hyprland/shell-binds.nix)
    "wallpaper-deck" # Wallpaper picker with Wallhaven (SUPER+CTRL+W, ../hyprland/shell-binds.nix)
  ];

  entries =
    src:
    map (dir: {
      name = dir;
      path = "${src}/${dir}";
    });
  selected =
    entries inputs.noctalia-official-plugins official
    ++ entries inputs.noctalia-community-plugins community;

  # One read-only `path` source: the documented way to ship plugins from Nix. Declaring any
  # [[plugins.source]] drops the default official/community git sources, so nothing is cloned
  # or auto-updated at runtime. Update with `nix flake update noctalia-*-plugins`.
  pluginSource = pkgs.linkFarm "noctalia-plugins" selected;
  pluginIds = map (p: (lib.importTOML "${p.path}/plugin.toml").id) selected;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    # One switch, in the host; NixOS owns the package and the user service.
    inherit enable;

    # Hand-written settings only. Anything changed in the GUI goes to
    # ~/.local/state/noctalia/settings.toml, which wins over this file.
    settings = {
      shell = {
        # Apps launched from Noctalia must outlive a restart of its user service.
        launch_apps_as_systemd_services = true;
        # Replaces the agent DMS provides (PolkitService); nothing else installs one.
        polkit_agent = true;
      };

      plugins = {
        enabled = pluginIds;
        source = [
          {
            name = "nix";
            kind = "path";
            location = "${pluginSource}";
            enabled = true;
          }
        ];
      };
    };
  };

  # Runtime tools of the plugins above that nothing else installs. bw, jq, fzf, docker,
  # herdr, tailscale, gpu-screen-recorder and xdg-open already come from other modules.
  home.packages = lib.mkIf enable [
    pkgs.hyprpicker # screen-toolkit color picker (tesseract, magick, zbar, ffmpeg come from elsewhere)
    pkgs.nix-search-tv
    pkgs.slurp
    pkgs.sshfs
  ];

  # Surface rules from the Noctalia Hyprland guide (no autostart: the user service starts
  # it). Its binds (launcher, settings, Alt+Tab, media keys) and the shell-dependent binds
  # of ../hyprland are in ../hyprland/shell-binds.nix and replace the DMS ones on the same keys; the
  # other `dms ipc` binds in dms.binds stay until DMS is dropped for good and only fail to
  # run once DMS is disabled. SUPER+S is the scratchpad there, and the Control Center
  # opens through SUPER+CTRL+A/B/N/D/P.
  wayland.windowManager.hyprland.extraConfig = lib.mkIf enable (
    lib.mkAfter ''

      -- Noctalia (programs.noctalia).
      hl.window_rule({
        match = { class = "dev.noctalia.Noctalia" },
        float = true,
        size = { 1080, 920 },
      })

      -- Blur for the bar, panels, dock and notifications; Noctalia animates them itself.
      hl.layer_rule({
        name = "noctalia",
        match = {
          namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
        },
        no_anim = true,
        ignore_alpha = 0.5,
        blur = true,
        blur_popups = true,
      })
    ''
  );
}
