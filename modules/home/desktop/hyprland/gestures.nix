# Touchpad gestures, rendered to hl.gesture() Lua for default.nix. The touchpad (libinput)
# only emits swipes with 3+ fingers and pinches with 2+; 5 fingers fire nothing, so 3 and
# 4 are what is bound. The 3-finger horizontal workspace swipe is in dms/binds.lua.
#
# Plane rule, like the keys: no modifier = navigation, SUPER = move/resize/capture,
# ALT = window actions, CTRL = continuous controls (volume, brightness) and
# monitor/group moves, SHIFT = media and shell toggles.
#
# Returns { lua; sheet; }: the Lua to inline, and hl.bind lines built from the same entries.
# DMS's keybind viewer parses hyprland.lua without running it and reads hl.bind only, so it
# cannot show gestures; default.nix puts `sheet` in an `if false then` block, where the
# viewer lists it and Hyprland never registers it. The stand-in dispatchers only choose the
# category the viewer files each line under.
{
  lib,
  shell,
  commands,
  terminal,
  wpctl,
}:

let
  toLua = lib.generators.toLua { };

  # Commands the gestures need that the keybinds do not (or that DMS binds in dms/binds.lua).
  shellCommands = {
    dms = {
      overview = "dms ipc call hypr toggleOverview";
      launcher = "dms ipc call spotlight toggle";
      playPause = "dms ipc call mpris playPause";
      brightnessUp = ''dms ipc call brightness increment 2 ""'';
      brightnessDown = ''dms ipc call brightness decrement 2 ""'';
    };
    noctalia = {
      launcher = "noctalia msg panel-toggle launcher";
      brightnessUp = "noctalia msg brightness-up";
      brightnessDown = "noctalia msg brightness-down";
    };
  };
  c = commands // shellCommands.${shell};

  # Action builders. `action` is the hl.gesture action; `stand` a stand-in dispatcher for
  # the sheet. A missing command gives null and the gesture is dropped.
  noop = ''hl.dsp.exec_cmd("")'';
  fn = body: {
    action = "function() ${body} end";
    stand = noop;
  };
  run =
    name:
    if c ? ${name} then
      fn "hl.exec_cmd(${toLua c.${name}})" // { stand = "hl.dsp.exec_cmd(${toLua c.${name}})"; }
    else
      null;
  dispatch = expr: fn "hl.dispatch(${expr})" // { stand = expr; };
  builtin =
    name: extra:
    {
      action = toLua name;
      stand =
        if
          lib.elem name [
            "fullscreen"
            "float"
            "close"
            "move"
            "resize"
          ]
        then
          "hl.dsp.window.${name}()"
        else
          noop;
    }
    // extra;
  # Continuous control: vertical swipe distance fires `up`/`down` once per STEP.
  live = up: down: {
    action = "live_step(function() ${up} end, function() ${down} end)";
    stand = noop;
  };
  sh = cmd: "hl.exec_cmd(${toLua cmd})";
  volume = delta: sh "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ ${delta}";
  brightness = name: if c ? ${name} then sh c.${name} else "";

  g = fingers: direction: mods: desc: act: {
    inherit
      fingers
      direction
      mods
      desc
      act
      ;
  };

  gestures = [
    # Navigation.
    (g 3 "up" "" "Overview" (run "overview"))
    (g 3 "down" "" "Scratchpad" (dispatch ''hl.dsp.workspace.toggle_special("scratchpad")''))
    (g 4 "left" "" "Previous window" (fn "cycle(false)"))
    (g 4 "right" "" "Next window" (fn "cycle(true)"))
    (g 4 "up" "" "Fullscreen" (builtin "fullscreen" { }))
    (g 4 "down" "" "Toggle floating" (builtin "float" { }))
    # zoomout = fingers together (pinch), zoomin = fingers apart (spread). They are Hyprland's
    # aliases of pinchout and pinchin, which its wiki describes the other way round: in
    # TrackpadGestures.cpp scale < 1 (fingers together) is PINCH_OUT.
    (g 3 "zoomout" "" "Launcher" (run "launcher"))
    (g 3 "zoomin" "" "Notification center" (run "notifyCenter"))
    (g 4 "zoomout" "" "Control Center" (run "controlCenter"))
    (g 4 "zoomin" "" "Quake terminal" (fn "quake(${toLua terminal})"))

    # SUPER: move, resize and capture the active window 1:1; zoom the screen.
    (g 3 "horizontal" "SUPER" "Move window" (builtin "move" { }))
    (g 3 "up" "SUPER" "Screenshot region to clipboard" (run "screenshotCopy"))
    (g 3 "down" "SUPER" "Quake terminal" (fn "quake(${toLua terminal})"))
    (g 4 "swipe" "SUPER" "Resize window" (builtin "resize" { }))
    # Without SUPER a 2-finger pinch is the apps' own zoom.
    (g 2 "pinch" "SUPER" "Zoom the screen at the cursor" (
      builtin "cursor_zoom" {
        zoom_level = 1;
        mode = "live";
      }
    ))

    # ALT: window actions.
    (g 3 "left" "ALT" "Window to previous workspace" (
      dispatch ''hl.dsp.window.move({ workspace = "e-1" })''
    ))
    (g 3 "right" "ALT" "Window to next workspace" (
      dispatch ''hl.dsp.window.move({ workspace = "e+1" })''
    ))
    (g 3 "up" "ALT" "Pop window out (float and pin)" (fn "pop()"))
    (g 3 "down" "ALT" "Close window" (builtin "close" { }))
    (g 4 "horizontal" "ALT" "Scroll the tape (scrolling layout)" (builtin "scroll_move" { }))
    (g 4 "up" "ALT" "Maximize" (builtin "fullscreen" { mode = "maximize"; }))
    (g 4 "down" "ALT" "Toggle dwindle/scrolling layout" (fn "layout_toggle()"))

    # CTRL: continuous controls and monitor/group moves.
    (g 3 "left" "CTRL" "Window to left monitor" (fn ''move_to_monitor("l")''))
    (g 3 "right" "CTRL" "Window to right monitor" (fn ''move_to_monitor("r")''))
    (g 3 "vertical" "CTRL" "Volume (up/down, live)" (live (volume "2%+") (volume "2%-")))
    (g 4 "left" "CTRL" "Previous window in group" (dispatch "hl.dsp.group.prev()"))
    (g 4 "right" "CTRL" "Next window in group" (dispatch "hl.dsp.group.next()"))
    (g 4 "vertical" "CTRL" "Brightness (up/down, live)" (
      live (brightness "brightnessUp") (brightness "brightnessDown")
    ))

    # SHIFT: media and shell toggles.
    (g 3 "left" "SHIFT" "Previous track" (run "mediaPrevious"))
    (g 3 "right" "SHIFT" "Next track" (run "mediaNext"))
    (g 3 "up" "SHIFT" "Play / pause" (run "playPause"))
    (g 3 "down" "SHIFT" "Toggle microphone mute" (
      fn (sh "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
    ))
    (g 4 "left" "SHIFT" "Focus previous monitor" (dispatch ''hl.dsp.focus({ monitor = "-1" })''))
    (g 4 "right" "SHIFT" "Focus next monitor" (dispatch ''hl.dsp.focus({ monitor = "+1" })''))
    (g 4 "up" "SHIFT" "Toggle bar" (run "barToggle"))
    (g 4 "down" "SHIFT" "Lock" (run "lock"))
  ];

  active = lib.filter (x: x.act != null) gestures;

  # Hyprland matches a gesture by fingers + direction + mods: the same triple twice is a typo.
  id = x: "${toString x.fingers} ${x.direction} ${x.mods}";
  duplicates = lib.attrNames (lib.filterAttrs (_: gs: lib.length gs > 1) (lib.groupBy id active));

  render =
    x:
    let
      fields = removeAttrs x.act [
        "action"
        "stand"
      ];
    in
    "hl.gesture({ fingers = ${toString x.fingers}, direction = ${toLua x.direction}${
      lib.optionalString (x.mods != "") ", mods = ${toLua x.mods}"
    }, action = ${x.act.action}${
      lib.concatMapStrings (k: ", ${k} = ${toLua fields.${k}}") (lib.attrNames fields)
    } })\n";

  # The viewer splits the key on "+" and shows each part as a keycap.
  arrow = {
    left = "←";
    right = "→";
    up = "↑";
    down = "↓";
    horizontal = "↔";
    vertical = "↕";
    swipe = "swipe";
    pinch = "pinch or spread";
    zoomout = "pinch";
    zoomin = "spread";
  };
  key =
    x:
    lib.optionalString (x.mods != "") "${x.mods} + "
    + "${toString x.fingers} fingers ${arrow.${x.direction}}";
  bind =
    key: stand: desc:
    "hl.bind(${toLua key}, ${stand}, { description = ${toLua desc} })\n";
in
assert lib.assertMsg (duplicates == [ ]) "Duplicate Hyprland gestures: ${toString duplicates}";
{
  lua = ''
    -- Touchpad gestures (gestures.nix). STEP is the swipe distance per volume or brightness
    -- step; raise it if the live gestures feel twitchy.
    local STEP = 25
    local function live_step(up, down)
      local acc = 0
      local function feed(e)
        acc = acc - e.delta.y -- swiping up is negative
        while acc >= STEP do acc = acc - STEP; up() end
        while acc <= -STEP do acc = acc + STEP; down() end
      end
      return { start = function(e) acc = 0; feed(e) end, update = feed }
    end
  ''
  + lib.concatMapStrings render active;

  sheet =
    "-- Not loaded by Hyprland: the gestures cheat sheet for DMS's keybind viewer.\n"
    +
      bind "3 fingers ↔" ''hl.dsp.focus({ workspace = "e+1" })''
        "Switch workspace (DMS, follows the fingers)"
    + lib.concatMapStrings (x: bind (key x) x.act.stand x.desc) active;
}
