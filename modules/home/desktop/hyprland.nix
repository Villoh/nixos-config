{ config, pkgs, ... }:

let
  # Per-client launch command and mute/deafen Hyprland dispatchers (Lua).
  # Pick the client with DISCORD in modules/home/core/defaults.nix.
  # Clients with a CLI act on the running instance, even hidden in the tray.
  # Concord and Vesktop have no CLI, so they get the keybind forwarded to
  # their window (Vesktop only works while its window is mapped, not in tray).
  cli = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
  discordClients = {
    concord = {
      launch = "ghostty -e concord";
      mute = ''hl.dsp.send_shortcut({ mods = "ALT", key = "m", window = "title:^(concord)$" })'';
      deafen = ''hl.dsp.send_shortcut({ mods = "ALT", key = "d", window = "title:^(concord)$" })'';
    };
    vesktop = {
      launch = "vesktop";
      mute = ''hl.dsp.send_shortcut({ mods = "CTRL_SHIFT", key = "m", window = "class:^(vesktop)$" })'';
      deafen = ''hl.dsp.send_shortcut({ mods = "CTRL_SHIFT", key = "d", window = "class:^(vesktop)$" })'';
    };
    equibop = {
      launch = "equibop";
      mute = cli "equibop --toggle-mic";
      deafen = cli "equibop --toggle-deafen";
    };
    legcord = {
      launch = "legcord";
      mute = cli "legcord --mute";
      deafen = cli "legcord --deafen";
    };
  };
  discord = discordClients.${config.home.sessionVariables.DISCORD};
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # NixOS owns the compositor, portal and session; HM owns personal Lua only.
    package = null;
    portalPackage = null;
    configType = "lua";
    # UWSM owns Hyprland's systemd session integration.
    systemd.enable = false;

    # Inline the literal imports so DMS can discover them in the personal main.
    extraConfig = builtins.readFile ../../nixos/desktop/hyprland-base.lua + ''
      hl.config({
        input = {
          kb_layout = "us",
          kb_variant = "intl",
        },
      })

      -- Open the configured Discord client.
      hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("${discord.launch}"))
      -- Open the default browser on a blank page.
      hl.bind("SUPER + B", hl.dsp.exec_cmd("xdg-open about:blank"))
      -- Open the editor selected by the user's environment.
      hl.bind("SUPER + C", hl.dsp.exec_cmd("${config.home.sessionVariables.EDITOR}"))
      -- Open WhatsApp in ZapFast.
      hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("zapfast"))

      -- Toggle Handy on press and release so Ctrl+Shift+Space behaves as
      -- push-to-talk. The CLI works reliably with the running instance.
      hl.bind("CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"))
      hl.bind("CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"), { release = true })
      -- Alternative: tap Super+D to start, tap again to stop. The delay lets Super
      -- be released before wtype types, otherwise letters fire as Super shortcuts.
      -- hl.bind("SUPER + D", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"))

      -- Toggle microphone and speaker mute, independent of hardware media keys.
      hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

      -- Send mute/deafen to the selected Discord client.
      hl.bind("SUPER + ALT + M", ${discord.mute})
      hl.bind("SUPER + ALT + D", ${discord.deafen})

      -- Capture and annotate a selected region with Quick Capture.
      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("dms screenshot"))

      -- Toggle the mise tools panel (DMS plugin).
      hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("dms ipc call mise toggle"))

      -- Omarchy-style pickers: theme profile (dmsProfiles) and wallpaper carousel.
      hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("dms ipc call profiles toggle"))
      hl.bind("SUPER + CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("dms ipc call wallpaperCarousel toggle"))

      -- Toggle the DMS emoji picker.
      hl.bind("SUPER + period", hl.dsp.exec_cmd("dms ipc call emojiPicker toggle"))

      -- Claude Quick Entry via the GlobalShortcuts portal: Hyprland only forwards
      -- it with an explicit bind. The id is stable across restarts and ends with
      -- the accelerator set in the app (Command+Shift+Space); changing it there
      -- changes the id, see `hyprctl globalshortcuts`.
      hl.bind("SUPER + ALT + C", hl.dsp.global("com.anthropic.Claude:FCF51C952DD85146214EE0EF1DBF3B2F-Command+Shift+C"))

      -- Claude Quick Entry is a 606x470 transparent floating window with only a
      -- bar drawn at the top; skip blur, shadow and border over the empty area.
      hl.window_rule({
        match = { class = "^com\\.anthropic\\.Claude$", float = true },
        no_blur = true,
        no_shadow = true,
        no_dim = true,
        border_size = 0,
      })

      -- Apply host-specific defaults after personal settings (e.g. keyboard).
      require("/etc/xdg/hypr/host")
    '';
  };

  # Chromium/Electron open a second ScreenCast portal dialog for the actual
  # stream; with restore tokens on by default the first pick is reused.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      allow_token_by_default = true
    }
  '';
}
