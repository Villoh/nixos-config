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
    # Serein registers its global shortcuts with the portal under a stable id per action
    # (see `hyprctl globalshortcuts`); the Nix build needs ViceVerse-cz/Serein#906 for that.
    serein = {
      launch = "serein";
      mute = ''hl.dsp.global("cz.viceverse.serein:toggle-mute")'';
      deafen = ''hl.dsp.global("cz.viceverse.serein:toggle-deafen")'';
    };
    # Yapfast has no CLI nor mute/deafen keys (only push-to-talk), so those binds do nothing.
    yapfast = {
      launch = "yapfast";
      mute = cli "true";
      deafen = cli "true";
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

  # Push-to-talk commands run on key press and key release.
  # Pick the client with DICTATION in modules/home/core/defaults.nix.
  # Handy only has a toggle, so it runs the same command on both edges.
  dictationClients = {
    handy = rec {
      press = "${pkgs.handy}/bin/handy --toggle-transcription";
      release = press;
    };
    hex = {
      press = "hex dictation start";
      release = "hex dictation stop";
    };
  };
  dictation = dictationClients.${config.home.sessionVariables.DICTATION};

  # Toggle the active workspace between dwindle and scrolling (Omarchy's
  # omarchy-hyprland-workspace-layout-toggle, through the Lua workspace rule).
  layoutToggle = pkgs.writeShellScript "workspace-layout-toggle" ''
    info=$(hyprctl activeworkspace -j)
    ws=$(${pkgs.jq}/bin/jq -r .id <<<"$info")
    case $(${pkgs.jq}/bin/jq -r .tiledLayout <<<"$info") in
      dwindle) new=scrolling ;;
      *) new=dwindle ;;
    esac
    hyprctl eval "hl.workspace_rule({ workspace = \"$ws\", layout = \"$new\" })" >/dev/null
    ${pkgs.libnotify}/bin/notify-send -a Hyprland -u low "Workspace layout" "Set to $new"
  '';

  # Quake console: spawn the terminal (the window rule shows its special workspace)
  # or toggle it when it already exists.
  quakeToggle = pkgs.writeShellScript "quake-toggle" ''
    if hyprctl clients | grep -q 'class: mikel.quake'; then
      hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("quake"))' >/dev/null
    else
      exec ${config.home.sessionVariables.TERMINAL} --class=mikel.quake
    fi
  '';
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

      -- Free Ctrl+Shift+R for apps (hard reload in browsers); DMS binds it to
      -- workspace rename. Case must match the DMS bind exactly.
      hl.unbind("CTRL + SHIFT + R")

      -- Omarchy-style key planes: SUPER = windows, SUPER+SHIFT = apps,
      -- SUPER+CTRL = panels, SUPER+CTRL+ALT = quick actions. Free the DMS
      -- binds that sit on keys of another plane (the SUPER+T terminal, float,
      -- fullscreen and the exit-Hyprland bind, which is also in the power menu).
      hl.unbind("SUPER + T")
      hl.unbind("SUPER + SHIFT + T")
      hl.unbind("SUPER + F")
      hl.unbind("SUPER + SHIFT + F")
      hl.unbind("SUPER + SHIFT + N")
      hl.unbind("SUPER + SHIFT + E")
      hl.unbind("SUPER + W")
      hl.unbind("SUPER + V")
      hl.unbind("SUPER + X")
      hl.unbind("SUPER + CTRL + H")
      hl.unbind("SUPER + CTRL + L")
      hl.unbind("SUPER + CTRL + left")
      hl.unbind("SUPER + CTRL + right")

      -- Windows: terminal, float, fullscreen, and maximize.
      hl.bind("SUPER + Return", hl.dsp.exec_cmd("${config.home.sessionVariables.TERMINAL}"))
      hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
      -- Close like Omarchy (SUPER+Q is the DMS bind); the DMS group toggle moves to G.
      hl.bind("SUPER + W", hl.dsp.window.close())

      -- Layout of the active workspace: dwindle <-> scrolling. Monitor focus
      -- stays on SUPER+arrows/H/L and CTRL+ALT+Tab, so SUPER+CTRL+H/L are free.
      hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("${layoutToggle}"))

      -- Cycle focus through monitors (Omarchy).
      hl.bind("CTRL + ALT + Tab", hl.dsp.focus({ monitor = "+1" }))
      hl.bind("CTRL + ALT + SHIFT + Tab", hl.dsp.focus({ monitor = "-1" }))

      -- Cycle through the windows of the workspace and raise the focused one:
      -- Alt+Tab (Omarchy) and SUPER+SHIFT+wheel for the mouse.
      local function cycle(forward)
        return function()
          hl.dispatch(hl.dsp.window.cycle_next({ next = forward }))
          hl.dispatch(hl.dsp.window.bring_to_top())
        end
      end
      hl.bind("ALT + Tab", cycle(true))
      hl.bind("ALT + SHIFT + Tab", cycle(false))
      hl.bind("SUPER + SHIFT + mouse_down", cycle(true))
      hl.bind("SUPER + SHIFT + mouse_up", cycle(false))

      -- Scratchpad: a named special workspace.
      hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))
      hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }))

      -- Groups (tabbed windows): toggle, leave, cycle, jump, and absorb a neighbor.
      hl.bind("SUPER + G", hl.dsp.group.toggle())
      hl.bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }))
      hl.bind("SUPER + ALT + Tab", hl.dsp.group.next())
      hl.bind("SUPER + ALT + SHIFT + Tab", hl.dsp.group.prev())
      hl.bind("SUPER + ALT + mouse_down", hl.dsp.group.next())
      hl.bind("SUPER + ALT + mouse_up", hl.dsp.group.prev())
      for i = 1, 5 do
        hl.bind("SUPER + ALT + " .. i, hl.dsp.group.active({ index = i }))
      end
      for key, dir in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
        hl.bind("SUPER + ALT + " .. key, hl.dsp.window.move({ into_group = dir }))
      end
      -- Move inside a group.
      hl.bind("SUPER + CTRL + left", hl.dsp.group.prev())
      hl.bind("SUPER + CTRL + right", hl.dsp.group.next())

      -- Quake console: a ghostty with its own class on special:quake, dropped
      -- under the bar. The first press spawns it, later ones toggle it.
      hl.window_rule({
        match = { class = "^mikel\\.quake$" },
        float = true,
        workspace = "special:quake",
        size = { "monitor_w * 0.8", "monitor_h * 0.45" },
        move = { "monitor_w * 0.1", 48 },
      })
      -- code:49 is the grave key; with the us-intl variant its keysym is dead_grave,
      -- so a bind on "grave" never fires.
      hl.bind("SUPER + code:49", hl.dsp.exec_cmd("${quakeToggle}"))
      hl.bind("SUPER + SHIFT + code:49", hl.dsp.window.move({ workspace = "special:quake" }))

      -- Apps with a role use the defaults (DMS Settings > Default Apps); the
      -- rest launch by desktop id.
      local dms = "dms ipc call "
      local launch = "${pkgs.gtk3}/bin/gtk-launch "
      hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(dms .. "defaultApp browser"))
      hl.bind("SUPER + SHIFT + ALT + B", hl.dsp.exec_cmd("${config.home.sessionVariables.BROWSER} --private-window"))
      hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(dms .. "defaultApp fileManager"))
      hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(dms .. "defaultApp textEditor"))
      hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(dms .. "defaultApp mail"))
      hl.bind("SUPER + SHIFT + ALT + E", hl.dsp.exec_cmd("xdg-open mailto:"))
      hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd(dms .. "defaultApp calendar"))
      hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("qalculate-qt"))
      hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("${config.home.sessionVariables.TERMINAL} -e btop"))
      hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(launch .. "com.anthropic.Claude"))
      hl.bind("SUPER + SHIFT + ALT + A", hl.dsp.exec_cmd(launch .. "codex-desktop"))
      hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(launch .. "org.telegram.desktop"))
      -- WhatsApp in ZapFast.
      hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("zapfast"))
      -- The configured Discord client.
      hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("${discord.launch}"))

      -- Push-to-talk dictation with the client selected by DICTATION. The CLI
      -- works reliably with the running instance.
      hl.bind("CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("${dictation.press}"))
      hl.bind("CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("${dictation.release}"), { release = true })
      -- Alternative: tap Super+D to start, tap again to stop. The delay lets Super
      -- be released before wtype types, otherwise letters fire as Super shortcuts.
      -- hl.bind("SUPER + D", hl.dsp.exec_cmd("${pkgs.handy}/bin/handy --toggle-transcription"))

      -- Toggle microphone (I = input) and speaker (O = output) mute, independent of hardware media keys.
      hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

      -- Send mute/deafen to the selected Discord client.
      hl.bind("SUPER + ALT + M", ${discord.mute})
      hl.bind("SUPER + ALT + D", ${discord.deafen})

      -- Omarchy-style capture binds via the Quick Capture plugin. Print and
      -- ALT+Print are also bound by DMS (dms/binds.lua), so free them first.
      hl.unbind("Print")
      hl.unbind("ALT + Print")
      local qc = "dms ipc call quickCapture "
      -- Region screenshot opened in the annotator (Print or SUPER+CTRL+ALT+C).
      hl.bind("Print", hl.dsp.exec_cmd(qc .. "screenshot region edit"))
      hl.bind("SUPER + CTRL + ALT + C", hl.dsp.exec_cmd(qc .. "screenshot region edit"))
      -- Windows-style: region straight to the clipboard, nothing saved.
      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(qc .. "screenshot region copy"))
      -- Capture menu, screenrecord toggle, and color picker.
      hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd(qc .. "toggle"))
      hl.bind("ALT + Print", hl.dsp.exec_cmd(qc .. "recordToggle region"))
      hl.bind("SUPER + Print", hl.dsp.exec_cmd("dms ipc call color-picker toggle"))

      -- Panels (SUPER+CTRL+key). Control Center sections are its widget ids.
      hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd(dms .. "control-center openWith audioOutput"))
      hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd(dms .. "control-center openWith bluetooth"))
      hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd(dms .. "control-center openWith wifi"))
      hl.bind("SUPER + CTRL + D", hl.dsp.exec_cmd(dms .. "settings openWith displays"))
      hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd(dms .. "powerprofile toggle"))
      hl.bind("SUPER + CTRL + E", hl.dsp.exec_cmd(dms .. "emojiPicker toggle"))

      -- Notifications (SUPER+, stays the DMS settings): act on the latest (open it
      -- or press its button), dismiss the latest, dismiss all popups, toggle Do Not
      -- Disturb.
      hl.bind("SUPER + CTRL + comma", hl.dsp.exec_cmd(dms .. "notifications invokeLast"))
      hl.bind("SUPER + ALT + comma", hl.dsp.exec_cmd(dms .. "notifications dismiss"))
      hl.bind("SUPER + SHIFT + comma", hl.dsp.exec_cmd(dms .. "notifications dismissAllPopups"))
      hl.bind("SUPER + CTRL + ALT + comma", hl.dsp.exec_cmd(dms .. "notifications toggleDoNotDisturb"))

      -- Next audio output, and show/hide the top bar.
      hl.bind("SHIFT + XF86AudioMute", hl.dsp.exec_cmd(dms .. "audio cycleoutput"), { locked = true })
      hl.bind("SUPER + SHIFT + space", hl.dsp.exec_cmd(dms .. "bar toggle index 0"))

      -- Workspaces: back to the previous one, move a window without following it,
      -- and send the workspace to the monitor in that direction.
      hl.bind("SUPER + CTRL + Tab", hl.dsp.focus({ workspace = "previous" }))
      for i = 1, 9 do
        hl.bind("SUPER + SHIFT + ALT + " .. i, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
      end
      for key, dir in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
        hl.bind("SUPER + SHIFT + ALT + " .. key, hl.dsp.workspace.move({ monitor = dir }))
      end

      -- Universal clipboard (Omarchy): SUPER+C/V/X/A work in any app. Terminals take
      -- CTRL+SHIFT for copy/paste and ignore cut and select-all, since CTRL+X/A would
      -- reach the shell. The clipboard history and the power menu move to SUPER+CTRL+V
      -- and SUPER+Escape.
      local terminals = { ["com.mitchellh.ghostty"] = true, ["mikel.quake"] = true, ["kitty"] = true }
      local function clip(key, terminal_mods)
        return function()
          local w = hl.get_active_window()
          local term = w and terminals[w.class]
          if term and not terminal_mods then return end
          hl.dispatch(hl.dsp.send_shortcut({ mods = term and terminal_mods or "CTRL", key = key }))
        end
      end
      hl.bind("SUPER + C", clip("c", "CTRL_SHIFT"))
      hl.bind("SUPER + V", clip("v", "CTRL_SHIFT"))
      hl.bind("SUPER + X", clip("x"))
      hl.bind("SUPER + A", clip("a"))
      hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd(dms .. "clipboard toggle"))
      hl.bind("SUPER + Escape", hl.dsp.exec_cmd(dms .. "powermenu toggle"))

      -- Quick actions (SUPER+CTRL+ALT+key): calendar panel and notepad.
      hl.bind("SUPER + CTRL + ALT + D", hl.dsp.exec_cmd(dms .. "dash toggle overview"))
      hl.bind("SUPER + CTRL + ALT + N", hl.dsp.exec_cmd(dms .. "notepad toggle"))

      -- Toggle the mise tools panel (DMS plugin).
      hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("dms ipc call mise toggle"))

      -- Omarchy-style pickers (dmsProfiles): wallpapers of the current folder
      -- (the frequent one, so the plain key) and the theme profile.
      hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("dms ipc call profiles wallpapers"))
      hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("dms ipc call profiles wallpapers"))
      hl.bind("SUPER + CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("dms ipc call profiles toggle"))
      hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("dms ipc call profiles toggle"))

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
