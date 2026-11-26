{ pkgs, ... }:

# A monitor switched to another input (a console on its HDMI) keeps its connector
# "connected", so Hyprland keeps giving it workspaces nobody can see. While a monitor is
# on another input its DDC/CI stops answering (tested on a TCL 27C2A), so that is the
# signal: a monitor that answered before and now stays silent is disabled, and its
# windows go to the other monitors. SUPER+CTRL+G does the same by hand on the focused
# monitor, and again to undo.
#
# Coming back is event driven: a monitor switched back to this host pulses HPD, which
# reaches us as a DRM hotplug uevent (tested on the TCL 27C2A). Each uevent brings any
# external monitor off in Hyprland back with `hyprctl reload` (a disabled output sends
# no signal, so the monitor would otherwise find nothing and fall back to its other
# input), then disables again those that stay silent on DDC. Leaving raises a uevent on
# the Acer VG280K (tested) but not on the TCL 27C2A: a TCL switched away needs
# SUPER+CTRL+G. A DDC poll every 10 s used to catch it, but ddcutil holds the NVIDIA
# driver lock and froze the game's render thread every 10 s. Monitors that never
# answered DDC (TVs, the laptop panel) are left alone, and the last active monitor is
# never disabled.
let
  monitor-input = pkgs.writeShellApplication {
    name = "monitor-input";
    runtimeInputs = [
      pkgs.ddcutil
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      off=$XDG_RUNTIME_DIR/monitor-input-off

      # VCP 0x60 is the input source; any successful read means the monitor is on this host.
      # A silent monitor makes ddcutil retry for ~12 s; cap it so one check stays short.
      ddc() { timeout 4 ddcutil --syslog never --edid "$1" --terse getvcp 60 </dev/null >/dev/null 2>&1; }
      # First 128 EDID bytes as hex, from the connector (the kernel keeps it while the
      # monitor looks at another input).
      edid_of() {
        for f in /sys/class/drm/card*-"$1"/edid; do
          if [ -r "$f" ]; then head -c128 "$f" | od -An -v -tx1 | tr -d ' \n'; return; fi
        done
      }
      disable() { hyprctl eval "hl.monitor({ output = \"desc:$1\", disabled = true })" >/dev/null; }
      flagged() { grep -qxF -- "$1" "$off" 2>/dev/null; }
      # A reload turns the laptop panel back on: with the lid closed, off again.
      reload() {
        hyprctl reload >/dev/null
        if grep -qs closed /proc/acpi/button/lid/*/state; then
          sleep 1
          hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })' >/dev/null
        fi
      }

      watch() {
        # A hyprctl hiccup (right after a reload, mid monitor change) must not kill the
        # watcher: nothing restarts it. The toggle keeps errexit.
        set +e
        declare -A edid seen
        acted=0

        # check 1: a uevent, light up monitors that are off. check 0: the timer, only look.
        check() {
          local d name desc dpms k gone total mons relight=0
          acted=0
          # Off in Hyprland and not by SUPER+CTRL+G: it may be back, light it up.
          if [ "$1" = 1 ]; then
            while IFS= read -r d; do
              if ! flagged "$d"; then relight=1; fi
            done < <(hyprctl monitors all -j | jq -r '.[] | select(.disabled and (.name | startswith("eDP") | not)) | .description')
          fi
          if [ "$relight" = 1 ]; then
            reload
            acted=1
            sleep 4 # link training; DDC answers a bit later
          fi

          mons=$(hyprctl monitors -j) || return 0
          total=$(jq length <<<"$mons")
          while IFS=$'\t' read -r name desc dpms; do
            case $name in eDP*) continue ;; esac
            if flagged "$desc"; then
              if [ "$total" -gt 1 ]; then disable "$desc"; acted=1; total=$((total - 1)); fi
              continue
            fi
            k=''${desc//[^A-Za-z0-9]/_}
            if [ -z "''${edid[$k]:-}" ]; then edid[$k]=$(edid_of "$name"); fi
            if [ -z "''${edid[$k]}" ]; then continue; fi
            # DDC may be silent in standby: not another input.
            if [ "$dpms" = false ]; then continue; fi
            if ddc "''${edid[$k]}"; then
              seen[$k]=1
            elif [ -n "''${seen[$k]:-}" ]; then
              # Silent for ~6 s straight: on another input, not a hiccup.
              gone=1
              for _ in 1 2 3; do
                sleep 2
                if ddc "''${edid[$k]}"; then gone=0; break; fi
              done
              if [ "$gone" = 1 ] && [ "$total" -gt 1 ]; then
                disable "$desc"
                acted=1
                total=$((total - 1))
              fi
            fi
          done < <(jq -r '.[] | [.name, .description, (.dpmsStatus | tostring)] | @tsv' <<<"$mons")
        }

        check 0 # learn which monitors answer DDC
        while true; do
          # Blocks until a uevent; fails only when udevadm is gone.
          IFS= read -r line || break
          case $line in UDEV*change*"(drm)") ;; *) continue ;; esac
          # One input change is a burst of uevents: wait for it to settle, check once.
          while read -r -t 2 _; do :; done
          check 1
          # Our own reload/disable raises uevents too, some of them late: ignore them
          # or this never ends.
          if [ "$acted" = 1 ]; then
            sleep 6
            while read -r -t 2 _; do :; done
          fi
        done < <(udevadm monitor --udev --subsystem-match=drm)
      }

      case "''${1:-watch}" in
        watch) watch ;;
        toggle)
          # Any external monitor disabled (by hand or by the watcher): bring them back.
          if [ "$(hyprctl monitors all -j | jq '[.[] | select(.disabled and (.name | startswith("eDP") | not))] | length')" -gt 0 ]; then
            rm -f "$off"
            reload
          else
            # Never the laptop panel: it would be left off with nothing to bring it back.
            desc=$(hyprctl monitors -j | jq -r '.[] | select(.focused and (.name | startswith("eDP") | not)) | .description')
            if [ -n "$desc" ] && [ "$(hyprctl monitors -j | jq length)" -gt 1 ]; then
              printf '%s\n' "$desc" >"$off"
              disable "$desc"
            else
              echo "monitor-input: focused monitor is the panel or the last active one, not disabling it" >&2
              exit 1
            fi
          fi
          ;;
        *) echo "usage: monitor-input [watch|toggle]" >&2; exit 1 ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ monitor-input ];

  # Session only (host-binds.lua is not loaded by the greeter). Started by Hyprland
  # so it inherits HYPRLAND_INSTANCE_SIGNATURE for hyprctl.
  environment.etc."xdg/hypr/host-binds.lua".text = ''
    hl.on("hyprland.start", function() hl.exec_cmd("monitor-input watch") end)
    hl.bind("SUPER + CTRL + G", hl.dsp.exec_cmd("monitor-input toggle"), { description = "Monitor on another input: toggle" })
  '';
}
