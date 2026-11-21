# Touchpad gestures, rendered to hl.gesture() Lua for default.nix. The touchpad (libinput)
# only emits swipes with 3+ fingers and pinches with 2+; 5 fingers fire nothing, so 3 and
# 4 are what is bound. The 3-finger horizontal workspace swipe is in dms/binds.lua.
#
# Plane rule, like the keys: no modifier = navigation, SUPER = move/resize/capture,
# ALT = window actions, CTRL = continuous controls (volume, brightness) and
# monitor/group moves, SHIFT = media and shell toggles.
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

  # Action builders. A missing command gives null and the gesture is dropped.
  fn = body: { action = "function() ${body} end"; };
  run = name: if c ? ${name} then fn "hl.exec_cmd(${toLua c.${name}})" else null;
  dispatch = expr: fn "hl.dispatch(${expr})";
  builtin = name: extra: { action = toLua name; } // extra;
  # Continuous control: vertical swipe distance fires `up`/`down` once per STEP.
  live = up: down: {
    action = "live_step(function() ${up} end, function() ${down} end)";
  };
  sh = cmd: "hl.exec_cmd(${toLua cmd})";
  volume = delta: sh "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ ${delta}";
  brightness = name: if c ? ${name} then sh c.${name} else "";

  g = fingers: direction: mods: act: {
    inherit
      fingers
      direction
      mods
      act
      ;
  };

  gestures = [
    # Navigation.
    (g 3 "up" "" (run "overview"))
    (g 3 "down" "" (dispatch ''hl.dsp.workspace.toggle_special("scratchpad")''))
    (g 4 "left" "" (fn "cycle(false)"))
    (g 4 "right" "" (fn "cycle(true)"))
    (g 4 "up" "" (builtin "fullscreen" { }))
    (g 4 "down" "" (builtin "float" { }))
    (g 3 "pinchin" "" (run "launcher"))
    (g 3 "pinchout" "" (run "notifyCenter"))
    (g 4 "pinchin" "" (run "controlCenter"))
    (g 4 "pinchout" "" (fn "quake(${toLua terminal})"))

    # SUPER: move, resize and capture the active window 1:1; zoom the screen.
    (g 3 "horizontal" "SUPER" (builtin "move" { }))
    (g 3 "up" "SUPER" (run "screenshotCopy"))
    (g 3 "down" "SUPER" (fn "quake(${toLua terminal})"))
    (g 4 "swipe" "SUPER" (builtin "resize" { }))
    # Without SUPER a 2-finger pinch is the apps' own zoom.
    (g 2 "pinch" "SUPER" (
      builtin "cursor_zoom" {
        zoom_level = 1;
        mode = "live";
      }
    ))

    # ALT: window actions.
    (g 3 "left" "ALT" (dispatch ''hl.dsp.window.move({ workspace = "e-1" })''))
    (g 3 "right" "ALT" (dispatch ''hl.dsp.window.move({ workspace = "e+1" })''))
    (g 3 "up" "ALT" (fn "pop()"))
    (g 3 "down" "ALT" (builtin "close" { }))
    (g 4 "horizontal" "ALT" (builtin "scroll_move" { }))
    (g 4 "up" "ALT" (builtin "fullscreen" { mode = "maximize"; }))
    (g 4 "down" "ALT" (fn "layout_toggle()"))

    # CTRL: continuous controls and monitor/group moves.
    (g 3 "left" "CTRL" (fn ''move_to_monitor("l")''))
    (g 3 "right" "CTRL" (fn ''move_to_monitor("r")''))
    (g 3 "vertical" "CTRL" (live (volume "2%+") (volume "2%-")))
    (g 4 "left" "CTRL" (dispatch "hl.dsp.group.prev()"))
    (g 4 "right" "CTRL" (dispatch "hl.dsp.group.next()"))
    (g 4 "vertical" "CTRL" (live (brightness "brightnessUp") (brightness "brightnessDown")))

    # SHIFT: media and shell toggles.
    (g 3 "left" "SHIFT" (run "mediaPrevious"))
    (g 3 "right" "SHIFT" (run "mediaNext"))
    (g 3 "up" "SHIFT" (run "playPause"))
    (g 3 "down" "SHIFT" (fn (sh "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle")))
    (g 4 "left" "SHIFT" (dispatch ''hl.dsp.focus({ monitor = "-1" })''))
    (g 4 "right" "SHIFT" (dispatch ''hl.dsp.focus({ monitor = "+1" })''))
    (g 4 "up" "SHIFT" (run "barToggle"))
    (g 4 "down" "SHIFT" (run "lock"))
  ];

  active = lib.filter (x: x.act != null) gestures;

  # Hyprland matches a gesture by fingers + direction + mods: the same triple twice is a typo.
  id = x: "${toString x.fingers} ${x.direction} ${x.mods}";
  duplicates = lib.attrNames (lib.filterAttrs (_: gs: lib.length gs > 1) (lib.groupBy id active));

  render =
    x:
    let
      fields = removeAttrs x.act [ "action" ];
    in
    "hl.gesture({ fingers = ${toString x.fingers}, direction = ${toLua x.direction}${
      lib.optionalString (x.mods != "") ", mods = ${toLua x.mods}"
    }, action = ${x.act.action}${
      lib.concatMapStrings (k: ", ${k} = ${toLua fields.${k}}") (lib.attrNames fields)
    } })\n";
in
assert lib.assertMsg (duplicates == [ ]) "Duplicate Hyprland gestures: ${toString duplicates}";
''
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
+ lib.concatMapStrings render active
