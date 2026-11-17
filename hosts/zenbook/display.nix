{ ... }:

{
  # Desk monitors, matched by EDID description so the layout follows them
  # through any port, dock or eGPU. The internal panel is off while a desk
  # monitor is connected, or while the lid is closed with any other monitor
  # connected (clamshell). Otherwise it stays on, so with the lid open at work
  # the laptop is a normal second screen. Merged with keyboard.nix; the greeter
  # already requires this file.
  environment.etc."xdg/hypr/host.lua".text = ''
    local ASUS = "ASUSTek COMPUTER INC VG259QM L9LMQS194060"
    local ACER = "Acer Technologies VG280K 0x0431B372"

    -- ASUS VG259QM on the left, Acer VG280K on the right, bottoms aligned.
    hl.monitor({
      output = "desc:" .. ASUS,
      mode = "1920x1080@239.760",
      position = "0x0",
      scale = 1,
    })
    hl.monitor({
      output = "desc:" .. ACER,
      mode = "3840x2160@59.997",
      position = "1920x-360",
      scale = 1.5,
    })

    -- Same pinning as desktop: workspace 1 on the ASUS, 6 on the Acer. Without
    -- those monitors the rules match nothing and workspaces go where Hyprland puts them.
    hl.workspace_rule({ workspace = "1", monitor = "desc:" .. ASUS, default = true })
    hl.workspace_rule({ workspace = "6", monitor = "desc:" .. ACER, default = true })

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
        if m.description == ASUS or m.description == ACER then desk = true end
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
  '';
}
