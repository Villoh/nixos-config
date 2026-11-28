-- Static part of the personal Hyprland main. default.nix inlines it after the dms.*
-- imports and before the keybinds, which call the helpers defined here.
-- The callers live in that generated part, so the helpers look unused from this file.
---@diagnostic disable: unused-local, unused-function

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "intl",
  },
  -- Plain black instead of Hyprland's default wallpaper, logo and splash quote while DMS loads.
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = 0xff000000,
  },
  -- Low-latency experiments (game-capture and Steam games). To roll back:
  --   freezes or colorful artifacts -> allow_tearing = false
  --   other glitches (cursor, screen captures) -> direct_scanout = 0
  -- 2 = direct scanout only for fullscreen windows with content type "game" (see the mpv rule below).
  render = {
    direct_scanout = 2,
  },
  -- Master switch: only windows with the `immediate` rule below tear, and only when fullscreen
  -- with nothing else on that monitor. Experimental; if an app freezes, set it to false.
  general = {
    allow_tearing = true,
  },
})

-- Keys freed from dms/binds.lua without a replacement (the keys default.nix binds
-- are unbound there automatically): the rest of DMS's SUPER+CTRL+H/J/K/L monitor focus,
-- which moves to SUPER+CTRL+ALT (L is the lock).
hl.unbind("SUPER + CTRL + H")
hl.unbind("SUPER + CTRL + J")
hl.unbind("SUPER + CTRL + K")

-- Passthrough for the Windows VM (windows-vm) or any remote desktop: SUPER+F12 turns every other
-- Hyprland bind off, so SUPER combos reach the focused window; press it again to get them back.
local function vm_keys(submap, message)
  return function()
    hl.dispatch(hl.dsp.submap(submap))
    hl.dispatch(hl.dsp.exec_cmd("dms ipc call toast info '" .. message .. "'"))
  end
end
hl.bind("SUPER + F12", vm_keys("vm", "Keys go to the window: SUPER+F12 to leave"))
hl.define_submap("vm", function()
  hl.bind("SUPER + F12", vm_keys("reset", "Keys back to Hyprland"))
end)

-- Cycle through the windows of the workspace and raise the focused one.
local function cycle(forward)
  return function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = forward }))
    hl.dispatch(hl.dsp.window.bring_to_top())
  end
end

-- Is there a monitor next to m in that direction (l/r/u/d)? Layout coordinates are
-- logical, so sizes are divided by scale.
local function has_monitor(m, dir)
  local mw, mh = m.width / m.scale, m.height / m.scale
  for _, o in ipairs(hl.get_monitors()) do
    if o.id ~= m.id then
      local ow, oh = o.width / o.scale, o.height / o.scale
      local overlap_y = o.y < m.y + mh and m.y < o.y + oh
      local overlap_x = o.x < m.x + mw and m.x < o.x + ow
      if (dir == "l" and overlap_y and o.x + ow <= m.x)
        or (dir == "r" and overlap_y and o.x >= m.x + mw)
        or (dir == "u" and overlap_x and o.y + oh <= m.y)
        or (dir == "d" and overlap_x and o.y >= m.y + mh) then
        return true
      end
    end
  end
  return false
end

-- Move the window to the monitor in that direction. The dispatcher prints "Invalid monitor"
-- itself (no Lua error to catch) when there is none, e.g. up/down on a row of monitors.
local function move_to_monitor(dir)
  return function()
    if has_monitor(hl.get_active_monitor(), dir) then
      hl.dispatch(hl.dsp.window.move({ monitor = dir }))
    end
  end
end

-- Universal clipboard (Omarchy): SUPER+C/V/X/A work in any app. Terminals take
-- CTRL+SHIFT for copy/paste and ignore cut and select-all, since CTRL+X/A would
-- reach the shell.
local terminals = { ["com.mitchellh.ghostty"] = true, ["mikel.quake"] = true, ["kitty"] = true }
local function clip(key, terminal_mods)
  return function()
    local w = hl.get_active_window()
    local term = w and terminals[w.class]
    if term and not terminal_mods then return end
    hl.dispatch(hl.dsp.send_shortcut({ mods = term and terminal_mods or "CTRL", key = key }))
  end
end

-- Omarchy window tools (omarchy-hyprland-window-* scripts, ported to Lua).
local function window_selector(w)
  return "address:" .. w.address
end

-- Pop the window out: float it at 1300x900, centered, pinned to every workspace and on
-- top. Again: unpin and tile it back.
local function pop()
  local w = hl.get_active_window()
  if not w then return end
  local window = window_selector(w)
  if w.pinned then
    hl.dispatch(hl.dsp.window.pin({ window = window, action = "off" }))
    hl.dispatch(hl.dsp.window.float({ window = window, action = "off" }))
    return
  end
  hl.dispatch(hl.dsp.window.float({ window = window, action = "on" }))
  hl.dispatch(hl.dsp.window.resize({ window = window, x = 1300, y = 900 }))
  hl.dispatch(hl.dsp.window.center({ window = window }))
  hl.dispatch(hl.dsp.window.pin({ window = window, action = "on" }))
  hl.dispatch(hl.dsp.window.alter_zorder({ window = window, mode = "top" }))
end

-- Close every window (a polite close: apps can still ask to save) and go to workspace 1.
local function close_all()
  for _, w in ipairs(hl.get_windows()) do
    hl.dispatch(hl.dsp.window.close({ window = window_selector(w) }))
  end
  hl.dispatch(hl.dsp.focus({ workspace = "1" }))
end

-- Tell the app it is fullscreen (a video hides its controls) while it keeps its tile.
local function tiled_fullscreen()
  local w = hl.get_active_window()
  if not w then return end
  local client = w.fullscreen_client == 2 and 0 or 2
  hl.dispatch(hl.dsp.window.fullscreen_state({ window = window_selector(w), internal = 0, client = client }))
end

-- Save and restore a window width per workspace and app (mostly for the scrolling
-- layout). Kept in a state file: Hyprland reloads this config, and with it the Lua
-- state, every time DMS rewrites a dms/*.lua fragment.
local widths_file = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
  .. "/hypr-window-widths"

local function read_widths()
  local widths = {}
  local f = io.open(widths_file, "r")
  if f then
    for line in f:lines() do
      local key, width = line:match("^(.-)\t(%d+)$")
      if key then widths[key] = tonumber(width) end
    end
    f:close()
  end
  return widths
end

local function width_key(w)
  local app = (w.class ~= "" and w.class) or (w.initial_class ~= "" and w.initial_class) or w.title
  return w.workspace.id .. ":" .. app
end

local function notify(text)
  hl.notification.create({ text = text, duration = 2500 })
end

local function save_width()
  local w = hl.get_active_window()
  if not w then return end
  local widths = read_widths()
  widths[width_key(w)] = w.size.x
  local f = io.open(widths_file, "w")
  if not f then return notify("Could not write " .. widths_file) end
  for key, width in pairs(widths) do
    f:write(key, "\t", width, "\n")
  end
  f:close()
  notify("Saved width " .. w.size.x .. " for " .. width_key(w))
end

-- A relative resize can grow the window to either side, and in some layouts a positive
-- step shrinks it: probe the sign first, then converge in a few steps (like Omarchy).
local function restore_width()
  local w = hl.get_active_window()
  if not w then return end
  local target = read_widths()[width_key(w)]
  if not target then return notify("No saved width for " .. width_key(w)) end
  local window = window_selector(w)
  local function resize_by(dx)
    hl.dispatch(hl.dsp.window.resize({ window = window, x = dx, y = 0, relative = true }))
  end
  local current = w.size.x
  if current == target then return end
  local direction
  for _, probe in ipairs({ 10, -10 }) do
    resize_by(probe)
    local now = w.size.x
    if now ~= current then
      direction = ((now - current) * probe > 0) and 1 or -1
      current = now
      break
    end
  end
  if not direction then return end
  for _ = 1, 6 do
    local delta = target - current
    if delta == 0 then break end
    resize_by(delta * direction)
    local now = w.size.x
    if now == current then break end
    current = now
  end
end

-- Toggle the active workspace between dwindle and scrolling, like Omarchy.
local function layout_toggle()
  local ws = hl.get_active_workspace()
  if not ws then return end
  local layout = ws.tiled_layout == "dwindle" and "scrolling" or "dwindle"
  hl.workspace_rule({ workspace = tostring(ws.id), layout = layout })
  notify("Workspace layout: Set to " .. layout)
end

-- Spawn the configured terminal or toggle its special workspace when it already exists.
local function quake(terminal)
  return function()
    for _, w in ipairs(hl.get_windows()) do
      if w.class == "mikel.quake" then
        hl.dispatch(hl.dsp.workspace.toggle_special("quake"))
        return
      end
    end
    hl.dispatch(hl.dsp.exec_cmd(terminal .. " --class=mikel.quake"))
  end
end

-- Quake console: a terminal with its own class on special:quake, dropped under the bar.
hl.window_rule({
  match = { class = "^mikel\\.quake$" },
  float = true,
  workspace = "special:quake",
  size = { "monitor_w * 0.8", "monitor_h * 0.45" },
  move = { "monitor_w * 0.1", 48 },
})

-- Claude Quick Entry is a 606x470 transparent floating window with only a bar drawn
-- at the top; skip blur, shadow and border over the empty area.
hl.window_rule({
  match = { class = "^com\\.anthropic\\.Claude$", float = true },
  no_blur = true,
  no_shadow = true,
  no_dim = true,
  border_size = 0,
})

-- The capture view is a game for Hyprland, so fullscreen it gets direct scanout (direct_scanout = 2)
-- and tearing, for the least latency.
hl.window_rule({
  match = { class = "^mpv$", title = "^Game capture$" },
  content = "game",
  immediate = true,
})

-- Steam/Proton games tear when fullscreen.
hl.window_rule({
  match = { class = "^steam_app_" },
  immediate = true,
})

-- yad dialogs (game-capture menu) are resizable, so Hyprland would tile them at full height.
hl.window_rule({
  match = { class = "^yad$" },
  float = true,
  size = { 480, 420 },
  move = { "monitor_w * 0.5 - 240", "monitor_h * 0.5 - 210" },
})

-- Mechvibes is laid out as a narrow, phone-like window; tiled it fills the screen with a
-- stretched column or leaves a hole beside it. shortcut: 520x900 is a guess at a comfortable
-- size, adjust after the first run.
hl.window_rule({
  match = { class = "^mechvibes$" },
  float = true,
  size = { 520, 900 },
  move = { "monitor_w * 0.5 - 260", "monitor_h * 0.5 - 450" },
})
