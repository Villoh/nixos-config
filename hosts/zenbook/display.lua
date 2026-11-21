local TCL = "Technical Concepts Ltd 27C2A P2611005101"
local ACER = "Acer Technologies VG280K 0x0431B372"

-- TCL 27C2A on the left, Acer VG280K on the right: both 4K at scale 1.5, so the
-- same logical height and no vertical offset. Only the TCL runs 10-bit: the
-- Acer is on HDMI 2.0, which has no bandwidth for 4K60 10-bit RGB. HDR is not
-- forced on the desktop (it looked dim and washed out); cm_auto_hdr below turns
-- it on for fullscreen HDR content.
hl.monitor({
  output = "desc:" .. TCL,
  mode = "3840x2160@160",
  position = "0x0",
  scale = 1.5,
  bitdepth = 10,
})
hl.monitor({
  output = "desc:" .. ACER,
  mode = "3840x2160@59.997",
  position = "2560x0",
  scale = 1.5,
})

-- Workspaces 1-5 on the first monitor, 6-10 on the second (an unpinned workspace
-- opens on the focused monitor), 11 on the laptop panel. Desk: TCL and Acer. Anywhere
-- else: the laptop panel and the first other monitor (or the panel again when alone).
-- Rules naming an absent monitor match nothing and Hyprland hands out 12, 13... instead.
local ws_key
local function set_workspaces(a, b, panel)
  if a .. b .. tostring(panel) == ws_key then return end
  ws_key = a .. b .. tostring(panel)
  -- Persistent, so the panel always has its own workspace and never gets a 12, 13...
  -- Only with two distinct monitors: a single screen shows just workspace 1.
  if panel ~= false then
    hl.workspace_rule({ workspace = "11", monitor = "eDP-1", default = a ~= b, persistent = a ~= b })
  end
  for i = 1, 10 do
    hl.workspace_rule({
      workspace = tostring(i),
      monitor = i <= 5 and a or b,
      default = i == 1 or (i == 6 and a ~= b),
      persistent = i == 1 or (i == 6 and a ~= b), -- always exists, so rehome() can move it when the rules come late
    })
  end
end

-- Same as desktop. Mixed-DPI XWayland apps handle their own scale. Note it also
-- applies on the laptop panel alone (see docs if X11 apps look tiny there).
hl.config({ xwayland = { force_zero_scaling = true } })

-- Focus follows the mouse and the cursor starts on the first connector (the external
-- monitor). Start it on the panel so apps launched at login open there; place() moves
-- it to the TCL at the desk. Ignored in clamshell, when the panel is off.
hl.config({ cursor = { default_monitor = "eDP-1" } })

-- Electron apps (Codex, Claude) trigger auto HDR on fullscreen, which turns on
-- wide gamut, and shows a warning on 8-bit outputs. 1 = HDR for fullscreen HDR
-- content (games), 0 = never.
hl.config({ render = { cm_auto_hdr = 1 } })

-- The state is recomputed from scratch each time, so the same code runs at
-- start and on every event. Pitfalls, from Hyprland discussions #14660 and
-- #14858 and the forum thread "Recovery from zero monitors":
-- - hl.monitor fires monitor.added/removed itself: act only when the wanted
--   state changes, and debounce the events.
-- - hl.monitor cannot enable an output when no monitor is active, so turning
--   the panel back on is `hyprctl reload`, which drops the runtime disable rule.
-- - The switch callback can report the old lid state in 0.57.2: read the lid
--   from /proc instead. If that fails the lid counts as open (desk logic still works).
-- - Switch binds must come after the hl.monitor rules, and reportedly stop
--   working in the same file as them: first thing to test on the laptop.
local function lid_closed()
  for _, n in ipairs({ "LID0", "LID", "LID1" }) do
    local ok, f = pcall(function() return io.open("/proc/acpi/button/lid/" .. n .. "/state") end)
    if ok and f then
      local s = f:read("*a")
      f:close()
      return s:find("closed", 1, true) ~= nil
    end
  end
  return false
end

local off
local function sync_panel()
  local desk, ext = false, false
  for _, m in ipairs(hl.get_monitors()) do
    if m.description == TCL or m.description == ACER then desk = true end
    if m.name ~= "eDP-1" then ext = ext or m.description end
  end
  -- Desk monitors do not turn the panel off: it stays as workspace 11 (the next free
  -- one) and a lifeline if the eGPU drops and takes the desk monitors with it.
  local want = ext and lid_closed()
  if desk then
    set_workspaces("desc:" .. TCL, "desc:" .. ACER)
  elseif want then
    -- Clamshell: the panel is about to go off, so everything moves to the other monitor.
    set_workspaces("desc:" .. ext, "desc:" .. ext, false)
  else
    set_workspaces("eDP-1", ext and ("desc:" .. ext) or "eDP-1")
  end
  if want == off then return end
  local first = off == nil
  off = want
  if want then
    hl.monitor({ output = "eDP-1", disabled = true })
  elseif not first then
    hl.exec_cmd("hyprctl reload")
  end
end

-- At login the monitors appear after this file ran, so each got whatever workspace
-- was free (11...) before the rules above were right. Once, with monitors present:
-- show 6 on its monitor, then 1, which focuses the main screen: the TCL at the desk,
-- the laptop panel when undocked, the only monitor in clamshell. Focus follows the
-- mouse, so the cursor goes to the middle of that screen too or it would pull the
-- focus back.
local function place()
  if #hl.get_monitors() == 0 then return end
  hl.dispatch(hl.dsp.focus({ workspace = "6" }))
  hl.dispatch(hl.dsp.focus({ workspace = "1" }))
  local m = hl.get_active_monitor()
  hl.dispatch(hl.dsp.cursor.move({ x = m.x + m.width / m.scale / 2, y = m.y + m.height / m.scale / 2 }))
end

-- At login the panel is the only monitor, so workspace 1 (and any app opened on it) is
-- created there; rules do not move an existing workspace, and the TCL would get 11.
-- Move workspaces 1-11 to their desk monitor. Idempotent; an absent monitor leaves its
-- workspaces where they are.
local function rehome()
  local mons = {}
  for _, m in ipairs(hl.get_monitors()) do
    mons[m.description] = m.name
    if m.name == "eDP-1" then mons.panel = m.name end
  end
  for _, w in ipairs(hl.get_workspaces()) do
    local want = mons[w.id == 11 and "panel" or w.id <= 5 and TCL or ACER]
    -- w.monitor is nil while its monitor is gone (input switch on the TCL).
    if w.id >= 1 and w.id <= 11 and want and (not w.monitor or w.monitor.name ~= want) then
      hl.dispatch(hl.dsp.workspace.move({ workspace = w.id, monitor = want }))
    end
  end
end

local placed
local timer = hl.timer(function()
  sync_panel()
  rehome()
  if not placed then placed = true; place() end
end, { timeout = 500, type = "oneshot" })
timer:set_enabled(false)
local function schedule()
  timer:set_enabled(false)
  timer:set_enabled(true)
end
hl.on("monitor.added", schedule)
hl.on("monitor.removed", schedule)
hl.bind("switch:on:Lid Switch", schedule, { locked = true })
hl.bind("switch:off:Lid Switch", schedule, { locked = true })
sync_panel()
hl.on("hyprland.start", place)
