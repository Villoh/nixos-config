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

      -- Hold Super+D (dictation) to record; release to transcribe and paste.
      hl.bind("SUPER + D", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"))
      hl.bind("SUPER + D", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"), { release = true })

      -- Toggle microphone and speaker mute, independent of hardware media keys.
      hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

      -- Send mute/deafen to the selected Discord client.
      hl.bind("SUPER + ALT + M", ${discord.mute})
      hl.bind("SUPER + ALT + D", ${discord.deafen})

      -- Capture and annotate a selected region with Quick Capture.
      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("dms screenshot"))

      -- Toggle the DMS emoji picker.
      hl.bind("SUPER + period", hl.dsp.exec_cmd("dms ipc call emojiPicker toggle"))

      -- Apply host-specific defaults after personal settings (e.g. keyboard).
      require("/etc/xdg/hypr/host")
    '';
  };
}
