local TCL = "Technical Concepts Ltd 27C2A P2611005101"
local ACER = "Acer Technologies VG280K 0x0431B372"

-- TCL 27C2A on the left, Acer VG280K on the right: both 4K at scale 1.5, so the
-- same logical height and no vertical offset.
hl.monitor({
  output = "desc:" .. TCL,
  mode = "3840x2160@160",
  position = "0x0",
  scale = 1.5,
})
hl.monitor({
  output = "desc:" .. ACER,
  mode = "3840x2160@59.997",
  position = "2560x0",
  scale = 1.5,
})

-- Workspaces 1-5 on the TCL, 6-10 on the Acer (an unpinned workspace opens on the
-- focused monitor). Without those monitors the rules match nothing and workspaces
-- go where Hyprland puts them.
for i = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(i),
    monitor = "desc:" .. (i <= 5 and TCL or ACER),
    default = i == 1 or i == 6,
  })
end

-- Same as desktop. Mixed-DPI XWayland apps handle their own scale. Note it also
-- applies on the laptop panel alone (see docs if X11 apps look tiny there).
hl.config({ xwayland = { force_zero_scaling = true } })

-- Electron apps (Codex, Claude) trigger auto HDR on fullscreen, which turns on
-- wide gamut and shows a warning. Set to 1 or 2 to use HDR.
hl.config({ render = { cm_auto_hdr = 0 } })

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
    if m.name ~= "eDP-1" then ext = true end
  end
  local want = desk or (ext and lid_closed())
  if want == off then return end
  local first = off == nil
  off = want
  if want then
    hl.monitor({ output = "eDP-1", disabled = true })
  elseif not first then
    hl.exec_cmd("hyprctl reload")
  end
end

local timer = hl.timer(sync_panel, { timeout = 500, type = "oneshot" })
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
