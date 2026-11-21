# Touchscreen gestures (hyprgrass plugin), rendered to Lua for default.nix like gestures.nix
# does for the touchpad. Only hosts that load the plugin get them (hosts/zenbook/touchscreen.nix).
#
# A touchscreen has no modifier keys under the fingers, so the shape of the gesture is the
# plane instead of SUPER/ALT/CTRL/SHIFT:
#   3 fingers = navigation        4 fingers = windows        5 fingers = destructive
#   edges     = shell panels and live controls (right edge volume, left edge brightness)
#   taps      = quick actions     hold + drag = move (3) and resize (4) the window
# 1 and 2 fingers stay with the apps (touch, scroll, pinch-zoom); 3+ never reach them.
#
# Pinch gestures match the touchpad's: fingers together (pinch) is `zoomout` and opens the
# launcher and Control Center; fingers apart (spread) is `zoomin`. hyprgrass reads the name
# with Hyprland's own parser, so these are the same aliases gestures.nix uses.
#
# Returns { lua; sheet; }: the Lua to inline, and hl.bind lines for DMS's keybind viewer
# (see gestures.nix for why those are binds).
{
  lib,
  shell,
  commands,
  terminal,
  wpctl,
}:

let
  toLua = lib.generators.toLua { };

  # Same extra commands as gestures.nix (that file keeps its own copy).
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

  # Actions. `api` is how hyprgrass takes it: `bind` for a discrete action (a dispatcher or
  # a Lua function), `gesture` for a built-in or live one. `stand` is the stand-in
  # dispatcher for the viewer. A missing command gives null and the gesture is dropped.
  noop = ''hl.dsp.exec_cmd("")'';
  discrete = action: stand: {
    api = "bind";
    inherit action stand;
  };
  fn = body: discrete "function() ${body} end" noop;
  run =
    name:
    if c ? ${name} then
      discrete "function() hl.exec_cmd(${toLua c.${name}}) end" "hl.dsp.exec_cmd(${toLua c.${name}})"
    else
      null;
  # A Lua value that already is the action: a dispatcher, or a config.lua helper that
  # returns the function to run (cycle, quake).
  expr = e: discrete e noop;
  dispatch = e: discrete e e;
  # Held touch that drags like a mouse button.
  mouse = e: discrete e e // { mouse = true; };
  builtin = name: {
    api = "gesture";
    action = toLua name;
    stand =
      if
        lib.elem name [
          "fullscreen"
          "float"
          "close"
        ]
      then
        "hl.dsp.window.${name}()"
      else
        noop;
  };
  # Continuous control: vertical swipe distance fires `up`/`down` once per STEP.
  live = up: down: {
    api = "gesture";
    action = "touch_step(function() ${up} end, function() ${down} end)";
    stand = noop;
  };
  sh = cmd: "hl.exec_cmd(${toLua cmd})";
  volume = delta: sh "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ ${delta}";
  brightness = name: if c ? ${name} then sh c.${name} else "";

  arrow = {
    left = "←";
    right = "→";
    up = "↑";
    down = "↓";
    horizontal = "↔";
    vertical = "↕";
    zoomin = "spread";
    zoomout = "pinch";
  };
  # hyprgrass names an edge by the side the finger starts on.
  side = {
    up = "top";
    down = "bottom";
    left = "left";
    right = "right";
  };

  # Patterns: `lua` is the pattern table, `label` the viewer key.
  swipe = fingers: direction: {
    lua = ''{ kind = "swipe", fingers = ${toString fingers}, direction = ${toLua direction} }'';
    label = "${toString fingers} fingers ${arrow.${direction}}";
  };
  pinch = fingers: direction: {
    lua = ''{ kind = "pinch", fingers = ${toString fingers}, direction = ${toLua direction} }'';
    label = "${toString fingers} fingers ${arrow.${direction}}";
  };
  tap = fingers: {
    lua = ''{ kind = "tap", fingers = ${toString fingers} }'';
    label = "${toString fingers} fingers tap";
  };
  hold = fingers: {
    lua = ''{ kind = "longpress", fingers = ${toString fingers} }'';
    # No "+" here: the viewer splits the key on it.
    label = "${toString fingers} fingers hold and drag";
  };
  edge = origin: direction: {
    lua = ''{ kind = "edge", origin = ${toLua origin}, direction = ${toLua direction} }'';
    label = "${side.${origin}} edge ${arrow.${direction}}";
  };

  t = pattern: desc: act: {
    inherit pattern desc act;
  };

  gestures = [
    # 3 fingers: navigation. The workspace swipe follows the fingers.
    (t (swipe 3 "horizontal") "Switch workspace (follows the fingers)" (builtin "workspace"))
    (t (swipe 3 "up") "Overview" (run "overview"))
    (t (swipe 3 "down") "Scratchpad" (dispatch ''hl.dsp.workspace.toggle_special("scratchpad")''))
    (t (pinch 3 "zoomout") "Launcher" (run "launcher"))
    (t (pinch 3 "zoomin") "Notification center" (run "notifyCenter"))
    (t (tap 3) "Play / pause" (run "playPause"))
    (t (hold 3) "Move window" (mouse "hl.dsp.window.drag()"))

    # 4 fingers: windows.
    (t (swipe 4 "left") "Previous window" (expr "cycle(false)"))
    (t (swipe 4 "right") "Next window" (expr "cycle(true)"))
    (t (swipe 4 "up") "Fullscreen" (builtin "fullscreen"))
    (t (swipe 4 "down") "Toggle floating" (builtin "float"))
    (t (pinch 4 "zoomout") "Control Center" (run "controlCenter"))
    (t (pinch 4 "zoomin") "Quake terminal" (expr "quake(${toLua terminal})"))
    (t (tap 4) "Screenshot region to clipboard" (run "screenshotCopy"))
    (t (hold 4) "Resize window" (mouse "hl.dsp.window.resize()"))

    # 5 fingers: destructive, hard to trigger by accident.
    (t (swipe 5 "left") "Window to previous workspace" (
      dispatch ''hl.dsp.window.move({ workspace = "e-1" })''
    ))
    (t (swipe 5 "right") "Window to next workspace" (
      dispatch ''hl.dsp.window.move({ workspace = "e+1" })''
    ))
    (t (swipe 5 "up") "Pop window out (float and pin)" (fn "pop()"))
    (t (swipe 5 "down") "Close window" (builtin "close"))
    (t (pinch 5 "zoomout") "Lock" (run "lock"))

    # Edges: one finger from the screen border.
    (t (edge "down" "up") "Launcher" (run "launcher"))
    (t (edge "up" "down") "Control Center" (run "controlCenter"))
    (t (edge "left" "right") "Overview" (run "overview"))
    (t (edge "right" "left") "Notification center" (run "notifyCenter"))
    (t (edge "right" "vertical") "Volume (up/down, live)" (live (volume "2%+") (volume "2%-")))
    (t (edge "left" "vertical") "Brightness (up/down, live)" (
      live (brightness "brightnessUp") (brightness "brightnessDown")
    ))
  ];

  active = lib.filter (x: x.act != null) gestures;

  # hyprgrass matches a pattern per API: the same one twice is a typo.
  id = x: "${x.act.api} ${x.pattern.lua}";
  duplicates = lib.attrNames (lib.filterAttrs (_: gs: lib.length gs > 1) (lib.groupBy id active));

  render =
    x:
    "  hl.plugin.hyprgrass.${x.act.api}({ pattern = ${x.pattern.lua}, action = ${x.act.action}${
        lib.optionalString (x.act.mouse or false) ", mouse = true"
      } })\n";
  sheetBind =
    x:
    "hl.bind(${toLua "Touch + ${x.pattern.label}"}, ${x.act.stand}, { description = ${toLua x.desc} })\n";
in
assert lib.assertMsg (duplicates == [ ]) "Duplicate touchscreen gestures: ${toString duplicates}";
{
  # The guard skips everything if the plugin failed to load (a Hyprland update it does not match).
  lua = ''
    -- Touchscreen gestures (touchscreen.nix). STEP is the swipe distance per volume or
    -- brightness step; raise it if the live gestures feel twitchy.
    if hl.plugin and hl.plugin.hyprgrass then
      local STEP = 25
      local function touch_step(up, down)
        local acc = 0
        local function feed(e)
          acc = acc - e.delta.y -- swiping up is negative
          while acc >= STEP do acc = acc - STEP; up() end
          while acc <= -STEP do acc = acc + STEP; down() end
        end
        return { start = function(e) acc = 0; feed(e) end, update = feed }
      end
  ''
  + lib.concatMapStrings render active
  + ''
    end
  '';

  sheet =
    "-- Not loaded by Hyprland: the touchscreen gestures cheat sheet for DMS's keybind viewer.\n"
    + lib.concatMapStrings sheetBind active;
}
