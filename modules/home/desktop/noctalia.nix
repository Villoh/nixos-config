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
    "herdr" # Herdr sessions and coding agents in the bar
    "mini-docker" # Docker containers
    "nix-search" # nixpkgs / NixOS / Home Manager search in the launcher (nix-search-tv)
    "phone-connect" # KDE Connect (NixOS enables it)
    "tailscale" # Tailscale peers and exit nodes (NixOS enables it)
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
    pkgs.nix-search-tv
    pkgs.slurp
    pkgs.sshfs
  ];

  # Binds and surface rules from the Noctalia Hyprland guide (no autostart: the user service
  # starts it). The `dms ipc` binds in hyprland.nix and dms.binds stay until DMS is dropped
  # for good; they only fail to run once DMS is disabled.
  wayland.windowManager.hyprland.extraConfig = lib.mkIf enable (
    lib.mkAfter ''

      -- Noctalia (programs.noctalia).
      hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
      hl.bind("SUPER + S", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
      hl.bind("SUPER + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
      hl.bind("ALT + Tab", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"))
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"))
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"))
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"))

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
