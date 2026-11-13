-- Test the callbacks without changing a running Hyprland session.
local workspace, windows, rule, notification
local calls = {}
local function noop() end
hl = {
  config = noop,
  unbind = noop,
  window_rule = noop,
  get_active_workspace = function() return workspace end,
  get_windows = function() return windows end,
  workspace_rule = function(value) rule = value end,
  notification = { create = function(value) notification = value end },
  dispatch = function(value) calls[#calls + 1] = value end,
  dsp = {
    exec_cmd = function(cmd) return "exec " .. cmd end,
    workspace = { toggle_special = function(name) return "toggle " .. name end },
  },
}
local f = assert(io.open(arg[1], "r"))
local source = f:read("*a")
f:close()
-- Production appends the generated binds in this same lexical scope.
local layout_toggle, quake = assert(load(source .. "\nreturn layout_toggle, quake"))()

layout_toggle()
assert(rule == nil and notification == nil)
for _, layout in ipairs({ "dwindle", "scrolling", "master" }) do
  workspace = { id = 3, tiled_layout = layout }
  layout_toggle()
  local expected = layout == "dwindle" and "scrolling" or "dwindle"
  assert(rule.workspace == "3" and rule.layout == expected)
  assert(notification.text == "Workspace layout: Set to " .. expected)
end

local toggle = quake("ghostty")
windows = {}
toggle()
assert(#calls == 1 and calls[1] == "exec ghostty --class=mikel.quake")
windows = { { class = "mikel.quake.other" } }
toggle()
assert(#calls == 2 and calls[2] == calls[1])
windows = { { class = "other" }, { class = "mikel.quake" }, { class = "mikel.quake" } }
toggle()
assert(#calls == 3 and calls[3] == "toggle quake")
quake("kitty")()
assert(#calls == 4 and calls[4] == "toggle quake")
windows = {}
quake("kitty")()
assert(#calls == 5 and calls[5] == "exec kitty --class=mikel.quake")
print("Hyprland layout and quake callbacks: OK")
