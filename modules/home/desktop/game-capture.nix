{ pkgs, ... }:

# Low-latency view of the ezcap401 capture card (PS5) in mpv: raw V4L2 frames, no buffering.
# `game-capture` is 4K60 NV12, `game-capture 1080` is 1080p120 and `game-capture menu` asks for
# resolution, frame rate, pixel format, latency, audio and fullscreen in a yad dialog. The
# launcher (`game-capture launcher`) opens a floating DMS form instead (./dms/game-capture, also a
# dash tab), which calls `game-capture run RES FPS FMT LAT AUDIO FS`; yad is the fallback.
# The sound is the video-capture loopback in modules/nixos/hardware/audio.nix; the menu starts
# or stops it. Close the window to stop. For the least latency play on the monitor on the
# card's HDMI OUT; this view is for the PC.
let
  # Stable by-id path: the /dev/videoN number changes between boots.
  # shortcut: serial hardcoded, parametrize if a 2nd ezcap shows up.
  device = "/dev/v4l/by-id/usb-ezc_ezcap401_EC4010001-video-index0";

  game-capture = pkgs.writeShellApplication {
    name = "game-capture";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.mpv
      pkgs.systemd
      pkgs.util-linux
      pkgs.yad
    ];
    text = ''
      res=3840x2160 fps=60 fmt=NV12 lat=Ultra audio=Loopback fs=FALSE
      case "''${1:-4k}" in
        4k) ;;
        1080)
          res=1920x1080
          fps=120
          ;;
        menu)
          # Limits on USB 3.2 Gen 2 (ezcap): 4K 60 NV12 / 50 YUYV / 144 MJPG; 1440p 144 NV12 /
          # 60 YUYV; 1080p 240 NV12 / 120 YUYV. A mode the card lacks makes mpv fail (notified).
          choice=$(yad --form --center --title="Game capture" --button="Start:0" --button="Cancel:1" \
            --text="4K: 60 fps NV12, 144 fps MJPG. 1440p: 144 NV12. 1080p: 240 NV12, 120 YUYV.\nLatency: Ultra = Lowest plus a 1-frame GPU queue (less lag, may stutter if the GPU is busy)." \
            --field="Resolution:CB" "^3840x2160!2560x1440!2560x1080!1920x1080!1280x720" \
            --field="Frame rate:CB" "^60!120!144!240!30" \
            --field="Pixel format:CB" "^NV12!YUYV!MJPG" \
            --field="Latency:CB" "^Ultra!Lowest!Low!Smooth" \
            --field="Audio:CB" "^Loopback!Off" \
            --field="Fullscreen:CHK" FALSE) || exit 0
          IFS='|' read -r res fps fmt lat audio fs _ <<< "$choice"
          ;;
        launcher)
          # `dms ipc call` exits 0 even for a missing target ("Target not found."), so check what
          # it printed. A new plugin file needs `dms ipc call plugins enable gameCapture` and a
          # `dms restart` before the target exists.
          [ "$(dms ipc call gameCapture show 2> /dev/null)" = GAME_CAPTURE_SHOWN ] || exec "$0" menu
          exit
          ;;
        run)
          res=$2 fps=$3 fmt=$4 lat=$5 audio=$6 fs=$7
          ;;
        *)
          echo "usage: game-capture [4k|1080|menu|launcher|run RES FPS FMT LAT AUDIO FS]" >&2
          exit 1
          ;;
      esac

      if [ ! -e ${device} ]; then
        notify-send -a "Game capture" -u critical "Game capture" "ezcap401 not found; check the USB cable"
        exit 1
      fi

      # One viewer at a time: the V4L2 device is exclusive. mpv inherits the lock.
      exec 9> "''${XDG_RUNTIME_DIR:-/tmp}/game-capture.lock"
      flock -n 9 || exit 0

      case "$audio" in
        Off) systemctl --user stop video-capture ;;
        *) systemctl --user start video-capture ;;
      esac

      case "$fmt" in
        YUYV) fmt=yuyv422 ;;
        MJPG) fmt=mjpeg ;;
        *) fmt=nv12 ;;
      esac

      opts=(--no-audio --title="Game capture")
      case "$lat" in
        Ultra) opts+=(--profile=low-latency --untimed --swapchain-depth=1) ;;
        Lowest) opts+=(--profile=low-latency --untimed) ;;
        Low) opts+=(--profile=low-latency) ;;
        *) ;;
      esac
      [ "$fs" = TRUE ] && opts+=(--fs)

      rc=0
      mpv av://v4l2:${device} \
        --demuxer-lavf-o=input_format="$fmt",video_size="$res",framerate="$fps" "''${opts[@]}" || rc=$?
      if [ "$rc" -eq 1 ] || [ "$rc" -eq 2 ]; then
        notify-send -a "Game capture" -u critical "Game capture" "Could not open $res $fps fps $fmt; try another mode"
      fi
    '';
  };

  # Toggles the video-capture loopback (the game sound in the headset) and says which way it went
  # with a DMS toast; notify-send when DMS is not the shell.
  capture-audio = pkgs.writeShellApplication {
    name = "capture-audio";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.systemd
    ];
    text = ''
      if systemctl --user is-active --quiet video-capture; then
        systemctl --user stop video-capture
        state=off
      else
        systemctl --user start video-capture
        state=on
      fi
      dms ipc call toast info "Capture audio $state" > /dev/null 2>&1 \
        || notify-send -a "Game capture" "Capture audio" "$state"
    '';
  };
in
{
  home.packages = [
    game-capture
    capture-audio
    (pkgs.makeDesktopItem {
      name = "capture-audio";
      desktopName = "Capture audio: toggle";
      comment = "Turn the capture card sound loopback on or off";
      exec = "capture-audio";
      icon = "audio-headphones";
      categories = [
        "AudioVideo"
        "Audio"
      ];
    })
    (pkgs.makeDesktopItem {
      name = "game-capture";
      desktopName = "Game capture";
      comment = "Low-latency view of the ezcap401 capture card";
      exec = "game-capture launcher";
      icon = "camera-video";
      categories = [
        "AudioVideo"
        "Video"
      ];
    })
  ];
}
