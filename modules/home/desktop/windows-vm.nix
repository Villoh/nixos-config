{ pkgs, ... }:

# On-demand Windows 11 VM: dockur/windows (QEMU/KVM in a Docker container) reached over RDP,
# the same approach as Omarchy's `omarchy-windows-vm`. The first launch downloads and installs
# Windows (10-30 min, progress at http://127.0.0.1:8006); the disk lives in ~/.windows and
# ~/Windows is shared into the VM. Closing the RDP window shuts the VM down.
# Needs modules/nixos/services/docker.nix, the docker group and /dev/kvm.
let
  # Only applied when Windows is installed: changing it later means `windows-vm remove` and
  # wiping ~/.windows (keep win11x64.iso to skip the download).
  username = "mikel";
  ram = "8G";
  cores = "4";
  disk = "64G";

  # "vendor:product" ids handed to the VM, e.g. [ "9886:0038" ]. The host loses the device
  # while the VM runs, so do not list audio devices you are listening through.
  usb = [ ];

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
      pkgs.openssl
    ];
    text = ''
      name=windows
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/windows"
      user=${username}

      case "''${1:-launch}" in
        stop)
          docker stop -t 120 "$name"
          exit
          ;;
        remove)
          # Drops the container so changed settings apply; the disk in ~/.windows stays.
          docker rm -f "$name"
          exit
          ;;
        reset)
          # Forgets the installed Windows (needed to change the username, disk size...). A
          # downloaded ISO is kept, so the next launch reinstalls without downloading again.
          read -r -p "Delete the Windows VM and its disk in ~/.windows? [y/N] " answer
          [ "$answer" = y ] || exit 1
          docker rm -f "$name" > /dev/null 2>&1 || true
          find "$HOME/.windows" -mindepth 1 -maxdepth 1 ! -name '*.iso' -delete
          echo "Windows VM reset; the next windows-vm launch installs it again."
          exit
          ;;
        launch) ;;
        *)
          echo "usage: windows-vm [launch|stop|remove|reset]" >&2
          exit 1
          ;;
      esac

      # RDP password: random, kept in a private file instead of the repo.
      mkdir -p "$cfg" "$HOME/.windows" "$HOME/Windows"
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
          -e TZ="$(timedatectl show -p Timezone --value 2> /dev/null || echo UTC)" \
          -e ARGUMENTS="-rtc base=localtime,clock=host,driftfix=slew ${usbArgs}" \
          -p 127.0.0.1:8006:8006 -p 127.0.0.1:3389:3389/tcp -p 127.0.0.1:3389:3389/udp \
          -v "$HOME/.windows:/storage" -v "$HOME/Windows:/shared" \
          --stop-timeout 120 \
          dockurr/windows > /dev/null
      elif [ "$(docker inspect -f '{{.State.Running}}' "$name")" != true ]; then
        docker start "$name" > /dev/null
      fi

      notify-send "Windows VM" "Starting; the first run installs Windows (see http://127.0.0.1:8006)" -t 10000
      # RDP only answers once Windows has booted (or finished installing), so retry until a
      # session is both established and lasts. xfreerdp exit codes of 128 and up mean the
      # connect failed (and a failed attempt can hang for minutes). A session that ends within
      # seconds was dropped by the server, as Windows does during first logon and setup.
      # Ctrl+C makes xfreerdp exit with 1 after a clean disconnect, so it is caught here instead.
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

      interrupted=false
      trap 'interrupted=true' INT
      connected=false
      for _ in $(seq 1 600); do
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
            notify-send -u critical "Windows VM" "RDP login failed for '$user'; container left running"
            exit 1
            ;;
          *) ;;
        esac
        if [ "$rc" -lt 128 ] && [ "$dur" -gt 10 ]; then
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
      if [ "$connected" = true ]; then
        docker stop -t 120 "$name" > /dev/null
      else
        notify-send -u critical "Windows VM" "Could not connect over RDP; container left running"
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
      exec = "windows-vm";
      icon = "windows-vm";
      categories = [
        "System"
        "Emulator"
      ];
    })
  ];
}
