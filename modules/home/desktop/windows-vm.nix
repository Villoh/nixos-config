{ pkgs, ... }:

# On-demand Windows 11 VM: dockur/windows (QEMU/KVM in a Docker container) reached over RDP,
# the same approach as Omarchy's `omarchy-windows-vm`. The first launch downloads and installs
# Windows (10-30 min, progress at http://127.0.0.1:8006); the disk lives in ~/.windows and
# ~/Windows is shared into the VM. Closing the RDP window shuts the VM down, unless it was
# started with `windows-vm launch --keep-alive`.
# `windows-vm launcher` opens the DMS form (./dms/windows-vm), or `windows-vm menu` (a yad dialog)
# when the plugin is not running; `snapshot`, `restore`, `snapshots` and `delete` manage checkpoints: cold copies of ~/.windows in ~/.local/share/windows-vm/snapshots.
# shortcut: a checkpoint is a full copy (about the used disk size each), move to qcow2 or libvirt
# snapshots if that gets too big or too slow.
# Needs modules/nixos/services/docker.nix, the docker group and /dev/kvm.
let
  # `username` and `disk` are only applied when Windows is installed: changing them later
  # means `windows-vm reset`. `ram` and `cores` apply to a new container (`windows-vm remove`).
  username = "mikel";
  ram = "8G";
  cores = "4";
  disk = "64G";

  # "vendor:product" ids handed to the VM, e.g. [ "9886:0038" ]. The host loses the device
  # while the VM runs, so do not list audio devices you are listening through.
  usb = [ ];

  # dockur's answer file installs Windows with UAC off (EnableLUA false), and Atlas Manager
  # refuses to install on a PC without it (its User account check). dockur runs `COMMAND` once,
  # at the end of the first install, so a new VM starts with UAC on from its next boot (the VM
  # shuts down when the RDP window closes). It does not touch a VM that is already installed:
  # there, `Set-ItemProperty` the same key by hand and restart.
  uacOn = ''reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f'';

  usbArgs = builtins.concatStringsSep " " (
    map (
      id:
      let
        parts = pkgs.lib.splitString ":" id;
      in
      "-device usb-host,vendorid=0x${builtins.elemAt parts 0},productid=0x${builtins.elemAt parts 1}"
    ) usb
  );

  windows-vm = pkgs.writeShellApplication {
    name = "windows-vm";
    runtimeInputs = [
      pkgs.docker
      pkgs.freerdp
      pkgs.jq
      pkgs.libnotify
      pkgs.util-linux
      pkgs.openssl
      pkgs.yad
    ];
    text = ''
      name=windows
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/windows"
      user=${username}

      # Status goes to a DMS toast (no history); falls back to a notification if DMS is down.
      running() { [ "$(docker inspect -f '{{.State.Running}}' "$name" 2> /dev/null)" = true ]; }

      toast() {
        dms ipc call toast info "$1" > /dev/null 2>&1 || notify-send -a "Windows VM" "Windows VM" "$1"
      }

      snapdir="''${XDG_DATA_HOME:-$HOME/.local/share}/windows-vm/snapshots"
      disk="$HOME/.windows"

      fail() {
        echo "windows-vm: $1" >&2
        notify-send -a "Windows VM" -u critical "Windows VM" "$1"
        exit 1
      }

      # A question in a terminal, a yad dialog when there is no tty (desktop action, DMS).
      confirm() {
        if [ -t 0 ]; then
          read -r -p "$1 [y/N] " answer
          [ "$answer" = y ]
        else
          yad --center --title="Windows VM" --image=dialog-question --text="$1" --button="Cancel:1" --button="Confirm:0"
        fi
      }

      valid_name() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; }

      # Checkpoint operations stop the VM first and start it again if it was running.
      stopped=false
      stop_vm() {
        if running; then
          toast "Windows VM: shutting down"
          docker stop -t 120 "$name" > /dev/null
          stopped=true
        fi
      }
      resume_vm() {
        if [ "$stopped" = true ]; then docker start "$name" > /dev/null; fi
      }

      # One checkpoint operation at a time (a double click in the DMS form would stop the VM twice).
      lock_checkpoints() {
        mkdir -p "$cfg" "$snapdir"
        exec 8> "$cfg/snapshot.lock"
        flock -n 8 || fail "another checkpoint operation is running"
      }

      # Everything in the disk folder but leftover ISOs (dockur deletes those itself).
      copy_files() {
        find "$1" -mindepth 1 -maxdepth 1 ! -name '*.iso' -exec cp -a --sparse=always {} "$2"/ \;
      }

      list_snapshots() {
        if [ -d "$snapdir" ]; then
          find "$snapdir" -mindepth 1 -maxdepth 1 -type d ! -name '*.tmp' -printf '%f\n' | sort
        fi
      }

      case "''${1:-launch}" in
        snapshots)
          list_snapshots
          exit
          ;;
        snapshot)
          snap=''${2:-$(date +%Y%m%d-%H%M%S)}
          valid_name "$snap" || fail "invalid checkpoint name '$snap' (letters, digits, . _ -)"
          lock_checkpoints
          [ ! -e "$snapdir/$snap" ] || fail "checkpoint '$snap' already exists"
          used=$(du -sk --exclude='*.iso' "$disk" | cut -f1)
          avail=$(df -k --output=avail "$snapdir" | tail -n 1)
          [ "$avail" -gt $((used + 5000000)) ] || fail "not enough free space for a checkpoint"
          toast "Windows VM: taking checkpoint '$snap' (about 30 s)"
          stop_vm
          # A leftover .tmp is an interrupted copy.
          rm -rf "''${snapdir:?}/$snap.tmp"
          mkdir "$snapdir/$snap.tmp"
          copy_files "$disk" "$snapdir/$snap.tmp" || {
            resume_vm
            fail "copy failed; nothing was saved"
          }
          mv "$snapdir/$snap.tmp" "$snapdir/$snap"
          resume_vm
          toast "Windows VM: checkpoint '$snap' saved"
          exit
          ;;
        restore)
          snap=''${2:?usage: windows-vm restore NAME [--yes]}
          valid_name "$snap" || fail "invalid checkpoint name '$snap'"
          [ -d "$snapdir/$snap" ] || fail "no checkpoint named '$snap'"
          if [ "''${3:-}" != --yes ] && [ "''${3:-}" != -y ]; then
            confirm "Replace the current Windows disk with checkpoint '$snap'? Changes since then are lost." || exit 1
          fi
          lock_checkpoints
          toast "Windows VM: restoring checkpoint '$snap' (about 30 s)"
          stop_vm
          copy_files "$snapdir/$snap" "$disk" || {
            resume_vm
            fail "restore failed; the disk may be inconsistent, restore again"
          }
          resume_vm
          toast "Windows VM: restored checkpoint '$snap'"
          exit
          ;;
        delete)
          snap=''${2:?usage: windows-vm delete NAME [--yes]}
          valid_name "$snap" || fail "invalid checkpoint name '$snap'"
          [ -d "$snapdir/$snap" ] || fail "no checkpoint named '$snap'"
          if [ "''${3:-}" != --yes ] && [ "''${3:-}" != -y ]; then
            confirm "Delete checkpoint '$snap'?" || exit 1
          fi
          lock_checkpoints
          rm -rf "''${snapdir:?}/$snap"
          toast "Windows VM: checkpoint '$snap' deleted"
          exit
          ;;
        menu)
          # The yad fallback of the DMS form: pick an action and a checkpoint, then it runs the
          # matching subcommand. The first checkpoint listed is the default one.
          ckpts=$(list_snapshots | paste -sd '!')
          choice=$(yad --form --center --title="Windows VM" --button="Run:0" --button="Cancel:1" \
            --text="State: $(docker inspect -f '{{.State.Status}}' "$name" 2> /dev/null || echo 'not created')\nCheckpoints are full copies of the Windows disk; the VM is shut down while one is taken or restored." \
            --field="Action:CB" "^Start!Start and keep running!Checkpoint now!Restore!Delete!Stop" \
            --field="Checkpoint (restore, delete):CB" "''${ckpts:--}" \
            --field="New checkpoint name (empty: date and time)") || exit 0
          IFS='|' read -r act ckpt snap_name _ <<< "$choice"
          case "$act" in
            Start) exec "$0" launch ;;
            "Start and keep running") exec "$0" launch --keep-alive ;;
            "Checkpoint now") exec "$0" snapshot ''${snap_name:+"$snap_name"} ;;
            Restore) exec "$0" restore "$ckpt" ;;
            Delete) exec "$0" delete "$ckpt" ;;
            *) exec "$0" stop ;;
          esac
          ;;
        launcher)
          # `dms ipc call` exits 0 even for a missing target ("Target not found."), so check what
          # it printed. A new plugin file needs `dms ipc call plugins enable windowsVm` and a
          # `dms restart` before the target exists.
          [ "$(dms ipc call windowsVm show 2> /dev/null)" = WINDOWS_VM_SHOWN ] || exec "$0" menu
          exit
          ;;
        stop)
          docker stop -t 120 "$name" > /dev/null
          echo "windows-vm: stopped"
          exit
          ;;
        status)
          docker inspect -f '{{.State.Status}}' "$name" 2> /dev/null || echo "not created"
          exit
          ;;
        remove)
          # Drops the container so changed settings apply; the disk in ~/.windows stays.
          docker rm -f "$name"
          exit
          ;;
        reset)
          # Forgets the installed Windows (needed to change the username or disk size). An ISO
          # left over from an unfinished install is kept; dockur deletes it once Windows is set up.
          read -r -p "Delete the Windows VM and its disk in ~/.windows? [y/N] " answer
          [ "$answer" = y ] || exit 1
          docker rm -f "$name" > /dev/null 2>&1 || true
          find "$HOME/.windows" -mindepth 1 -maxdepth 1 ! -name '*.iso' -delete
          echo "Windows VM reset; the next windows-vm launch installs it again."
          exit
          ;;
        launch | -k | --keep-alive) ;;
        *)
          echo "usage: windows-vm [launch [--keep-alive]|launcher|menu|stop|status|remove|reset|snapshots|snapshot [NAME]|restore NAME [--yes]|delete NAME [--yes]]" >&2
          exit 1
          ;;
      esac

      # Leave the VM running after the RDP window closes.
      keep_alive=false
      for arg in "$@"; do
        case "$arg" in
          -k | --keep-alive) keep_alive=true ;;
          *) ;;
        esac
      done

      if [ ! -e /dev/kvm ]; then
        echo "windows-vm: /dev/kvm is missing; enable virtualization in the BIOS" >&2
        notify-send -a "Windows VM" -u critical "Windows VM" "/dev/kvm is missing; enable virtualization in the BIOS"
        exit 1
      fi

      # RDP password: random, kept in a private file instead of the repo.
      mkdir -p "$cfg" "$HOME/.windows" "$HOME/Windows"

      # One launcher at a time: a second RDP login kicks the first, and the two loops would
      # keep reconnecting each other forever.
      exec 9> "$cfg/lock"
      flock -n 9 || { toast "Windows VM: already running"; exit 0; }
      if [ ! -e "$cfg/password" ]; then
        (umask 077 && openssl rand -hex 12 > "$cfg/password")
      fi
      pass=$(cat "$cfg/password")

      if ! docker inspect "$name" > /dev/null 2>&1; then
        docker run -d --name "$name" \
          --device /dev/kvm --device /dev/net/tun \
          ${pkgs.lib.optionalString (usb != [ ]) "--device /dev/bus/usb"} \
          --cap-add NET_ADMIN \
          -e VERSION=11 -e RAM_SIZE=${ram} -e CPU_CORES=${cores} -e DISK_SIZE=${disk} \
          -e USERNAME="$user" -e PASSWORD="$pass" \
          -e COMMAND='${uacOn}' \
          -e TZ="$(timedatectl show -p Timezone --value 2> /dev/null || echo UTC)" \
          -e ARGUMENTS="-rtc base=localtime,clock=host,driftfix=slew ${usbArgs}" \
          -p 127.0.0.1:8006:8006 -p 127.0.0.1:3389:3389/tcp -p 127.0.0.1:3389:3389/udp \
          -v "$HOME/.windows:/storage" -v "$HOME/Windows:/shared" \
          --stop-timeout 120 \
          dockurr/windows > /dev/null
        # First run: show the Windows install progress.
        xdg-open http://127.0.0.1:8006 > /dev/null 2>&1 || true
      elif ! running; then
        docker start "$name" > /dev/null
      fi

      toast "Windows VM: starting"

      # XWayland windows are not scaled by Hyprland, so Windows must do it: RDP only accepts
      # 100, 140 or 180 %. Uses the focused monitor, where the launcher was clicked.
      pct=$(hyprctl monitors -j 2> /dev/null | jq -r '[.[] | select(.focused)][0].scale * 100 | round' 2> /dev/null || echo 100)
      if [ "$pct" -ge 170 ] 2> /dev/null; then
        rdp_scale=180
      elif [ "$pct" -ge 130 ] 2> /dev/null; then
        rdp_scale=140
      else
        rdp_scale=100
      fi

      # RDP only answers once Windows has booted (or finished installing), so retry until a
      # session is both established and lasts. xfreerdp exit codes of 128 and up mean the
      # connect failed (and a failed attempt can hang for minutes). A session that ends within
      # seconds was dropped by the server, as Windows does during first logon and setup.
      # Ctrl+C makes xfreerdp exit with 1 after a clean disconnect, so it is caught here instead.
      interrupted=false
      trap 'interrupted=true' INT
      connected=false
      for _ in $(seq 1 600); do
        # Container gone (e.g. `windows-vm stop`): nothing left to reconnect to.
        running || break
        rc=0
        start=$(date +%s)
        xfreerdp /u:"$user" /p:"$pass" /v:127.0.0.1:3389 /cert:ignore /title:"Windows" \
          /dynamic-resolution /scale:"$rdp_scale" /gfx:AVC444 /sound /microphone /clipboard -grab-keyboard || rc=$?
        dur=$(($(date +%s) - start))
        echo "windows-vm: xfreerdp exited with $rc after ''${dur}s" >&2
        case "$rc" in
          # Wrong user or password: retrying cannot fix it (134 seen in practice; 132 and 135
          # are authentication failure and locked-out account, from memory).
          132 | 134 | 135)
            notify-send -a "Windows VM" -u critical "Windows VM" "RDP login failed for '$user'; container left running"
            exit 1
            ;;
          *) ;;
        esac
        if [ "$rc" -lt 128 ] && [ "$dur" -gt 10 ]; then
          connected=true
          break
        fi
        # xfreerdp exits 0 when the user closes its window (a server drop reports an error
        # code): treat it as a normal close, so it neither reopens nor leaves the VM running.
        if [ "$rc" -eq 0 ]; then
          connected=true
          break
        fi
        # Ctrl+C: stop reconnecting, and shut the VM down only if a session had been up.
        if [ "$interrupted" = true ]; then
          [ "$dur" -gt 10 ] && connected=true
          break
        fi
        sleep 5
        [ "$interrupted" = true ] && break
      done

      # Never stop a VM that was not reached (e.g. Windows is still installing).
      if [ "$connected" = true ] && [ "$keep_alive" = true ]; then
        toast "Windows VM: Still running; stop it with: windows-vm stop"
      elif [ "$connected" = true ]; then
        toast "Windows VM: Shutting down..."
        docker stop -t 120 "$name" > /dev/null
        toast "Windows VM: Stopped"
      elif running; then
        notify-send -a "Windows VM" -u critical "Windows VM" "Could not connect over RDP; container left running"
      fi
    '';
  };
in
{
  home.packages = [
    windows-vm
    # Flat four-square Windows logo, drawn here so the launcher does not depend on an icon theme.
    (pkgs.writeTextDir "share/icons/hicolor/scalable/apps/windows-vm.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
        <g fill="#0078d4">
          <rect x="24" y="24" width="100" height="100"/>
          <rect x="132" y="24" width="100" height="100"/>
          <rect x="24" y="132" width="100" height="100"/>
          <rect x="132" y="132" width="100" height="100"/>
        </g>
      </svg>
    '')
    (pkgs.makeDesktopItem {
      name = "windows-vm";
      desktopName = "Windows";
      comment = "Windows 11 VM over RDP (stops when the window closes)";
      exec = "windows-vm launcher";
      icon = "windows-vm";
      actions = {
        start = {
          name = "Start now";
          exec = "windows-vm launch";
        };
        keep-alive = {
          name = "Start and keep running";
          exec = "windows-vm launch --keep-alive";
        };
        checkpoint = {
          name = "Checkpoint now";
          exec = "windows-vm snapshot";
        };
        restore-base = {
          name = "Restore checkpoint base";
          exec = "windows-vm restore base";
        };
        stop = {
          name = "Stop";
          exec = "windows-vm stop";
        };
      };
      categories = [
        "System"
        "Emulator"
      ];
    })
  ];
}
