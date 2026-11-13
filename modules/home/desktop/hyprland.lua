-- Static part of the personal Hyprland main. hyprland.nix inlines it after the dms.*
-- imports and before the keybinds, which call the helpers defined here.

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "intl",
  },
})

-- Keys freed from dms/binds.lua without a replacement (the keys hyprland.nix binds
-- are unbound there automatically): Ctrl+Shift+R stays the hard reload in browsers
-- (DMS: workspace rename), and SUPER+CTRL+H goes with SUPER+CTRL+L, the layout toggle.
hl.unbind("CTRL + SHIFT + R")
hl.unbind("SUPER + CTRL + H")

-- Cycle through the windows of the workspace and raise the focused one.
local function cycle(forward)
  return function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = forward }))
    hl.dispatch(hl.dsp.window.bring_to_top())
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

-- Quake console: a ghostty with its own class on special:quake, dropped under the bar.
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
