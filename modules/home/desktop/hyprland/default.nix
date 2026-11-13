{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (config.home.sessionVariables) BROWSER TERMINAL;

  # Bind entries: { key; desc; exec | dsp + args | lua; opts? }, built with these helpers.
  # `exec` runs a command, `dsp` is an hl.dsp dispatcher with its argument (a table as a
  # Nix attrset, a string, or { } for none), `lua` is a raw Lua expression. Entries
  # without an action are dropped, so a client without some command just loses the bind.
  exec = key: desc: cmd: {
    inherit key desc;
    exec = cmd;
  };
  dsp = key: desc: name: args: {
    inherit key desc args;
    dsp = name;
  };
  lua = key: desc: expr: {
    inherit key desc;
    lua = expr;
  };
  action =
    key: desc: a:
    { inherit key desc; } // a;

  # Per-client launch command and mute/deafen actions.
  # Pick the client with DISCORD in modules/home/core/defaults.nix.
  # Clients with a CLI act on the running instance, even hidden in the tray.
  # Concord and Vesktop have no CLI, so they get the keybind forwarded to
  # their window (Vesktop only works while its window is mapped, not in tray).
  shortcut = mods: key: window: {
    dsp = "send_shortcut";
    args = { inherit mods key window; };
  };
  cli = cmd: { exec = cmd; };
  discordClients = {
    concord = {
      launch = "ghostty -e concord";
      mute = shortcut "ALT" "m" "title:^(concord)$";
      deafen = shortcut "ALT" "d" "title:^(concord)$";
    };
    vesktop = {
      launch = "vesktop";
      mute = shortcut "CTRL_SHIFT" "m" "class:^(vesktop)$";
      deafen = shortcut "CTRL_SHIFT" "d" "class:^(vesktop)$";
    };
    # Serein registers its global shortcuts with the portal under a stable id per action
    # (see `hyprctl globalshortcuts`); the Nix build needs ViceVerse-cz/Serein#906 for that.
    serein = {
      launch = "serein";
      mute = {
        dsp = "global";
        args = "cz.viceverse.serein:toggle-mute";
      };
      deafen = {
        dsp = "global";
        args = "cz.viceverse.serein:toggle-deafen";
      };
    };
    # Yapfast has no CLI nor mute/deafen keys (only push-to-talk): no binds.
    yapfast.launch = "yapfast";
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

  # Push-to-talk commands run on key press and key release; `toggle` starts or stops.
  # Pick the client with DICTATION in modules/home/core/defaults.nix.
  # Handy only has a toggle, so it runs the same command on both edges.
  dictationClients = {
    handy = rec {
      toggle = "${pkgs.handy}/bin/handy --toggle-transcription";
      press = toggle;
      release = toggle;
    };
    hex = {
      toggle = "hex dictation toggle";
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

  # Quake console: spawn the terminal (the window rule in hyprland.lua shows its
  # special workspace) or toggle it when it already exists.
  quakeToggle = pkgs.writeShellScript "quake-toggle" ''
    if hyprctl clients | grep -q 'class: mikel.quake'; then
      hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("quake"))' >/dev/null
    else
      exec ${TERMINAL} --class=mikel.quake
    fi
  '';

  launch = id: "${pkgs.gtk3}/bin/gtk-launch ${id}";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  directions = {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  };
  forDirections = f: lib.mapAttrsToList f directions;
  forNumbers = n: f: map f (lib.range 1 n);

  # Binds that call the desktop shell (apps by role, captures, panels, notifications,
  # pickers...): keys once, commands per shell. See shell-binds.nix.
  noctalia = osConfig.programs.noctalia.enable;
  shellBinds = import ./shell-binds.nix {
    inherit lib pkgs;
    shell = if noctalia then "noctalia" else "dms";
  };

  # Omarchy-style key planes: SUPER = windows, SUPER+SHIFT = apps, SUPER+CTRL = panels,
  # SUPER+CTRL+ALT = quick actions, SUPER+ALT = variants.
  binds = [
    # Windows.
    (exec "SUPER + Return" "Terminal" TERMINAL)
    (exec "SUPER + ALT + Return" "Terminal with tmux" "${TERMINAL} -e tmux")
    (exec "SUPER + CTRL + Return" "Herdr" "herdr-app")
    (dsp "SUPER + T" "Toggle floating" "window.float" { action = "toggle"; })
    (dsp "SUPER + F" "Fullscreen" "window.fullscreen" {
      mode = "fullscreen";
      action = "toggle";
    })
    (dsp "SUPER + ALT + F" "Maximize" "window.fullscreen" {
      mode = "maximized";
      action = "toggle";
    })
    # Close like Omarchy (SUPER+Q is the DMS bind); the DMS group toggle moves to G.
    (dsp "SUPER + W" "Close window" "window.close" { })
    # Omarchy's layout plane (SUPER+L stays the DMS focus-right; lock is SUPER+CTRL+L).
    (exec "SUPER + ALT + L" "Toggle layout dwindle/scrolling" "${layoutToggle}")
    (dsp "CTRL + ALT + Tab" "Next monitor" "focus" { monitor = "+1"; })
    (dsp "CTRL + ALT + SHIFT + Tab" "Previous monitor" "focus" { monitor = "-1"; })
    # Omarchy window tools (Lua functions in hyprland.lua). Omarchy has them on SUPER+O/P
    # and SUPER+Home, which DMS uses for the overview, monitor profiles and focus.
    (lua "SUPER + ALT + T" "Pop window out (float & pin)" "pop")
    (dsp "SUPER + ALT + P" "Pseudo window" "window.pseudo" { })
    (lua "SUPER + CTRL + F" "Tiled fullscreen" "tiled_fullscreen")
    (lua "SUPER + ALT + Home" "Save window width" "save_width")
    (lua "SUPER + CTRL + Home" "Restore window width" "restore_width")
    (lua "SUPER + SHIFT + mouse_down" "Next window" "cycle(true)")
    (lua "SUPER + SHIFT + mouse_up" "Previous window" "cycle(false)")

    # Scratchpad: a named special workspace.
    (dsp "SUPER + S" "Scratchpad" "workspace.toggle_special" "scratchpad")
    (dsp "SUPER + ALT + S" "Move window to scratchpad" "window.move" {
      workspace = "special:scratchpad";
    })

    # Quake console. code:49 is the grave key; with the us-intl variant its keysym is
    # dead_grave, so a bind on "grave" never fires.
    (exec "SUPER + code:49" "Quake terminal" "${quakeToggle}")
    (dsp "SUPER + SHIFT + code:49" "Move window to quake" "window.move" {
      workspace = "special:quake";
    })

    # Groups (tabbed windows).
    (dsp "SUPER + G" "Toggle group" "group.toggle" { })
    (dsp "SUPER + ALT + G" "Move window out of group" "window.move" { out_of_group = true; })
    (dsp "SUPER + ALT + Tab" "Next window in group" "group.next" { })
    (dsp "SUPER + ALT + SHIFT + Tab" "Previous window in group" "group.prev" { })
    (dsp "SUPER + ALT + mouse_down" "Next window in group" "group.next" { })
    (dsp "SUPER + ALT + mouse_up" "Previous window in group" "group.prev" { })
    (dsp "SUPER + CTRL + right" "Next window in group" "group.next" { })
    (dsp "SUPER + CTRL + left" "Previous window in group" "group.prev" { })
  ]
  ++ forNumbers 5 (
    i: dsp "SUPER + ALT + ${toString i}" "Group window ${toString i}" "group.active" { index = i; }
  )
  ++ forDirections (
    key: dir:
    dsp "SUPER + ALT + ${key}" "Move window into group ${key}" "window.move" { into_group = dir; }
  )
  ++ [
    # Workspaces. Next/previous stay on the focused monitor, like Omarchy; the DMS
    # overview keeps SUPER+O.
    (dsp "SUPER + Tab" "Next workspace" "focus" { workspace = "m+1"; })
    (dsp "SUPER + SHIFT + Tab" "Previous workspace" "focus" { workspace = "m-1"; })
    (dsp "SUPER + CTRL + Tab" "Former workspace" "focus" { workspace = "previous"; })
  ]
  ++ forNumbers 9 (
    i:
    dsp "SUPER + SHIFT + ALT + ${toString i}" "Move window to workspace ${toString i} silently"
      "window.move"
      {
        workspace = toString i;
        follow = false;
      }
  )
  ++ forDirections (
    key: dir:
    dsp "SUPER + SHIFT + ALT + ${key}" "Move workspace to monitor ${key}" "workspace.move" {
      monitor = dir;
    }
  )
  ++ [
    # Apps by desktop id or command; the ones with a role are in shell-binds.nix.
    # SUPER+SHIFT+N stays the DMS notepad toggle.
    (exec "SUPER + SHIFT + ALT + B" "Private browser window" "${BROWSER} --private-window")
    (exec "SUPER + SHIFT + ALT + M" "New mail" "xdg-open mailto:")
    (exec "SUPER + SHIFT + Q" "Calculator" "qalculate-qt")
    (exec "SUPER + SHIFT + T" "System monitor" "${TERMINAL} -e btop")
    (exec "SUPER + SHIFT + A" "Claude" (launch "com.anthropic.Claude"))
    (exec "SUPER + SHIFT + ALT + A" "Codex" (launch "codex-desktop"))
    (exec "SUPER + SHIFT + G" "Telegram" (launch "org.telegram.desktop"))
    (exec "SUPER + SHIFT + Z" "WhatsApp (ZapFast)" "zapfast")
    (exec "SUPER + SHIFT + ALT + G" "WhatsApp (ZapFast)" "zapfast")
    # YouTube Music; Omarchy's music key (SUPER+SHIFT+M) is mail here.
    (exec "SUPER + SHIFT + Y" "Music (Meiro)" (launch "meiro"))
    # V for vault; Omarchy's SUPER+SHIFT+/ stays the DMS cheatsheet.
    (exec "SUPER + SHIFT + V" "Password manager (Bitwarden)" (launch "bitwarden"))
    (exec "SUPER + SHIFT + D" "Discord" discord.launch)
    # Claude Quick Entry through the GlobalShortcuts portal: Hyprland only forwards it
    # with an explicit bind. The id is stable across restarts and ends with the
    # accelerator set in the app (Command+Shift+C); changing it there changes the id,
    # see `hyprctl globalshortcuts`.
    (dsp "SUPER + ALT + C" "Claude Quick Entry" "global"
      "com.anthropic.Claude:FCF51C952DD85146214EE0EF1DBF3B2F-Command+Shift+C"
    )

    # Audio and voice. Push-to-talk dictation with the client selected by DICTATION.
    (exec "CTRL + SHIFT + SPACE" "Dictation (hold)" dictation.press)
    (exec "CTRL + SHIFT + SPACE" "Dictation (release)" dictation.release // { opts.release = true; })
    # Omarchy's tap-to-dictate. Not its hold-Right-Alt: with us-intl that key is AltGr,
    # which types the accents. The DMS spotlight bar moves to SUPER+ALT+SPACE.
    (exec "ALT + SPACE" "Dictation (start/stop)" dictation.toggle)
    # I = input, O = output, independent of the hardware media keys.
    (exec "SUPER + ALT + I" "Toggle microphone mute" "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
    (exec "SUPER + ALT + O" "Toggle speaker mute" "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle")
    (action "SUPER + ALT + M" "Discord: toggle mute" (discord.mute or { }))
    (action "SUPER + ALT + D" "Discord: toggle deafen" (discord.deafen or { }))

    # Universal clipboard (clip() in hyprland.lua).
    (lua "SUPER + C" "Copy" ''clip("c", "CTRL_SHIFT")'')
    (lua "SUPER + V" "Paste" ''clip("v", "CTRL_SHIFT")'')
    (lua "SUPER + X" "Cut" ''clip("x")'')
    (lua "SUPER + A" "Select all" ''clip("a")'')
  ]
  # Noctalia has its own Alt+Tab window switcher (shell-binds.nix).
  ++ lib.optionals (!noctalia) [
    (lua "ALT + Tab" "Next window" "cycle(true)")
    (lua "ALT + SHIFT + Tab" "Previous window" "cycle(false)")
  ]
  ++ shellBinds;

  active = lib.filter (b: b ? exec || b ? dsp || b ? lua) binds;

  # Lua rendering. Tables keep bare keys so DMS's keybind viewer reads `description`.
  toLua = lib.generators.toLua { };
  luaValue =
    v:
    if lib.isAttrs v then
      "{ ${lib.concatStringsSep ", " (lib.mapAttrsToList (k: x: "${k} = ${luaValue x}") v)} }"
    else
      toLua v;
  luaAction =
    b:
    if b ? exec then
      "hl.dsp.exec_cmd(${toLua b.exec})"
    else if b ? dsp then
      "hl.dsp.${b.dsp}(${lib.optionalString (b.args != { }) (luaValue b.args)})"
    else
      b.lua;
  renderBind =
    b:
    "hl.bind(${toLua b.key}, ${luaAction b}, ${
      luaValue ({ description = b.desc; } // b.opts or { })
    })\n";

  # The same keystroke bound twice fires both actions; fail the build instead.
  # Modifier order and case do not matter to Hyprland, so neither do they here.
  keystroke =
    b:
    let
      parts = lib.splitString "+" (lib.toLower (lib.replaceStrings [ " " ] [ "" ] b.key));
    in
    lib.concatStringsSep "+" (lib.sort lib.lessThan (lib.init parts) ++ [ (lib.last parts) ])
    + lib.optionalString (b.opts.release or false) " (release)";
  duplicates = lib.attrNames (
    lib.filterAttrs (_: bs: lib.length bs > 1) (lib.groupBy keystroke active)
  );

  # Unbind every key first: dms/binds.lua (seeded by DMS, user-writable) may bind any of
  # them, and a second bind would fire both. Hyprland matches unbinds by the key string
  # ignoring case and spaces, so a DMS bind with the modifiers in another order survives.
  keybinds =
    assert lib.assertMsg (duplicates == [ ]) "Duplicate Hyprland binds: ${toString duplicates}";
    lib.concatMapStrings (key: "hl.unbind(${toLua key})\n") (lib.unique (map (b: b.key) active))
    + lib.concatMapStrings renderBind active;
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
    # Host-specific defaults go last, after the personal settings (e.g. keyboard).
    extraConfig = lib.concatStrings [
      (builtins.readFile ../../../nixos/desktop/dms/hyprland-base.lua)
      (builtins.readFile ./hyprland.lua)
      keybinds
      ''
        require("/etc/xdg/hypr/host")
      ''
    ];
  };

  # Chromium/Electron open a second ScreenCast portal dialog for the actual
  # stream; with restore tokens on by default the first pick is reused.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      allow_token_by_default = true
    }
  '';
}
