# Keybinds that depend on the desktop shell (DMS or Noctalia). The keys are written
# once in `binds`; each shell only supplies the commands in `shells.<shell>`. An action
# the active shell has no command for is skipped, and the app actions fall back to
# xdg-open / gtk-launch, which work with any shell. Returns bind entries for
# default.nix, which renders them.
{
  lib,
  pkgs,
  shell,
}:

let
  gtkLaunch = "${pkgs.gtk3}/bin/gtk-launch";
  mimeApp = mime: ''${gtkLaunch} "$(xdg-mime query default ${mime})"'';

  # Control Center section as a toggle: `openWith` only opens, so close it when that
  # same section is already showing (the last one opened is kept in the runtime dir).
  ccPanel = pkgs.writeShellScript "cc-panel" ''
    state="$XDG_RUNTIME_DIR/dms-cc-section"
    if [ "$(dms ipc call control-center status)" = visible ] && [ "$(cat "$state" 2>/dev/null)" = "$1" ]; then
      dms ipc call control-center hide
    else
      echo "$1" > "$state"
      dms ipc call control-center openWith "$1"
    fi
  '';

  # Shell-independent defaults for the actions that open an app by role.
  fallback = {
    browser = "xdg-open about:blank";
    files = "xdg-open ~";
    editor = mimeApp "text/plain";
    mail = "xdg-open mailto:";
    calendar = mimeApp "text/calendar";
  };

  shells = {
    dms =
      let
        ipc = cmd: "dms ipc call ${cmd}";
      in
      {
        browser = ipc "defaultApp browser";
        files = ipc "defaultApp fileManager";
        editor = ipc "defaultApp textEditor";
        mail = ipc "defaultApp mail";
        calendar = ipc "defaultApp calendar";
        # Quick Capture plugin.
        screenshot = ipc "quickCapture screenshot region edit";
        screenshotCopy = ipc "quickCapture screenshot region copy";
        screenshotWindow = ipc "quickCapture screenshot window edit";
        screenshotFull = ipc "quickCapture screenshot full edit";
        captureMenu = ipc "quickCapture toggle";
        # Screen Capture Toolbar plugin.
        captureToolbar = ipc "screenCaptureToolbar toggle";
        record = ipc "quickCapture recordToggle region";
        colorPicker = ipc "color-picker toggle";
        audioPanel = "${ccPanel} audioOutput";
        bluetoothPanel = "${ccPanel} bluetooth";
        networkPanel = "${ccPanel} wifi";
        displaysPanel = ipc "settings toggleWith displays";
        powerPanel = ipc "powerprofile toggle";
        calendarPanel = ipc "dash toggle overview";
        emoji = ipc "emojiPicker toggle";
        notifyInvoke = ipc "notifications invokeLast";
        notifyDismiss = ipc "notifications dismiss";
        notifyDismissAll = ipc "notifications dismissAllPopups";
        notifyDnd = ipc "notifications toggleDoNotDisturb";
        notifyCenter = ipc "notifications toggle";
        audioOutputCycle = ipc "audio cycleoutput";
        barToggle = ipc "bar toggle index 0";
        clipboardHistory = ipc "clipboard toggle";
        powerMenu = ipc "powermenu toggle";
        controlCenter = ipc "control-center toggle";
        renameWorkspace = ipc "workspace-rename open";
        launcherBar = ipc "spotlight-bar toggle";
        mediaNext = ipc "mpris next";
        mediaPrevious = ipc "mpris previous";
        lock = ipc "lock lock";
        idleInhibit = ipc "inhibit toggle";
        miseTools = ipc "mise toggle";
        # dmsProfiles plugin.
        wallpaperPicker = ipc "profiles wallpapers";
        themePicker = ipc "profiles toggle";
        # wallhavenCarousel plugin.
        wallhavenCarousel = ipc "wallhavenCarousel toggle";
        # launcher, settings and the media keys come with dms/binds.lua.
      };

    # Commands from the Noctalia IPC docs (docs/user/ipc) and the plugin READMEs, not run on
    # a live Noctalia yet. Without an entry: mise (a DMS plugin).
    noctalia =
      let
        msg = cmd: "noctalia msg ${cmd}";
        cc = tab: msg "panel-toggle control-center ${tab}";
      in
      {
        screenshot = msg "screenshot-region --annotate";
        screenshotCopy = msg "screenshot-region --copy-to-clipboard --no-save-to-file --no-annotate";
        screenshotWindow = msg "screenshot-window";
        controlCenter = msg "panel-toggle control-center";
        record = msg "plugin noctalia/screen_recorder:service all toggle";
        # screen-toolkit: its panel is the capture menu.
        captureMenu = msg "plugin alexander/screen-toolkit:service all toggle";
        colorPicker = msg "plugin alexander/screen-toolkit:service all colorPicker";
        ocr = msg "plugin alexander/screen-toolkit:service all ocr";
        emoji = msg "panel-toggle liamwh/emoji-picker:compact";
        audioOutputCycle = msg "plugin blackbartblues/audio-switcher:service all cycle-output";
        audioPanel = cc "audio";
        bluetoothPanel = cc "bluetooth";
        networkPanel = cc "network";
        displaysPanel = cc "monitor";
        powerPanel = cc "power";
        calendarPanel = cc "calendar";
        notifyInvoke = msg "notification-invoke-latest";
        # Noctalia has no command for a single toast: clear the visible ones (history stays).
        notifyDismiss = msg "notification-clear-active";
        notifyDismissAll = msg "notification-clear-active";
        notifyDnd = msg "notification-dnd-toggle";
        notifyCenter = cc "notifications";
        barToggle = msg "bar-toggle";
        clipboardHistory = msg "panel-toggle clipboard";
        powerMenu = msg "panel-toggle session";
        lock = msg "session lock";
        mediaNext = msg "media next";
        mediaPrevious = msg "media previous";
        idleInhibit = msg "caffeine-toggle";
        # Community plugins listed in ../noctalia/default.nix.
        wallpaperPicker = msg "panel-toggle ishan0121/wallpaper-deck:picker";
        themePicker = msg "panel-toggle theblackdon/theme-switcher:carousel";
        # From the Noctalia Hyprland guide; DMS has these in dms/binds.lua.
        launcher = msg "panel-toggle launcher";
        settings = msg "settings-toggle";
        windowSwitcher = msg "window-switcher hold";
        volumeUp = msg "volume-up";
        volumeDown = msg "volume-down";
        volumeMute = msg "volume-mute";
        brightnessUp = msg "brightness-up";
        brightnessDown = msg "brightness-down";
      };
  };

  commands = fallback // shells.${shell};

  bind = key: action: desc: { inherit key action desc; };
  # Volume and brightness keys also work on the lock screen and repeat while held.
  media =
    bind:
    bind
    // {
      opts = {
        locked = true;
        repeating = true;
      };
    };
  locked = bind: bind // { opts.locked = true; };

  # Plane rule (Omarchy): SUPER+SHIFT apps, SUPER+CTRL panels and pickers,
  # SUPER+CTRL+ALT quick actions, SUPER+ALT variants.
  binds = [
    (bind "SUPER + SHIFT + B" "browser" "Browser")
    (bind "SUPER + SHIFT + Return" "browser" "Browser")
    (bind "SUPER + SHIFT + F" "files" "File manager")
    (bind "SUPER + SHIFT + E" "editor" "Text editor")
    (bind "SUPER + SHIFT + M" "mail" "Mail")
    (bind "SUPER + SHIFT + C" "calendar" "Calendar")

    (bind "Print" "screenshot" "Screenshot region (annotate)")
    (bind "SUPER + CTRL + ALT + C" "screenshot" "Screenshot region (annotate)")
    (bind "SUPER + SHIFT + S" "screenshotCopy" "Screenshot region to clipboard")
    (bind "SUPER + CTRL + C" "captureMenu" "Capture menu")
    (bind "SUPER + CTRL + Print" "captureToolbar" "Capture toolbar")
    (bind "ALT + Print" "record" "Toggle screen recording")
    (bind "SHIFT + Print" "screenshotWindow" "Screenshot window")
    (bind "CTRL + Print" "screenshotFull" "Screenshot full screen (annotate)")
    (bind "SUPER + Print" "colorPicker" "Color picker")
    (bind "SUPER + CTRL + Print" "ocr" "OCR region")

    (bind "SUPER + CTRL + A" "audioPanel" "Audio panel")
    (bind "SUPER + CTRL + B" "bluetoothPanel" "Bluetooth panel")
    (bind "SUPER + CTRL + N" "networkPanel" "Network panel")
    (bind "SUPER + CTRL + D" "displaysPanel" "Displays panel")
    (bind "SUPER + CTRL + P" "powerPanel" "Power profile panel")
    (bind "SUPER + CTRL + ALT + D" "calendarPanel" "Calendar panel")
    (bind "SUPER + CTRL + E" "emoji" "Emoji picker")
    (bind "SUPER + period" "emoji" "Emoji picker")
    (bind "SUPER + CTRL + V" "clipboardHistory" "Clipboard history")
    (bind "SUPER + Escape" "powerMenu" "Power menu")
    # Omarchy's toggle menu; the Control Center sections have their own keys above.
    (bind "SUPER + CTRL + O" "controlCenter" "Control Center")
    # The current DMS key (older dms/binds.lua had CTRL+SHIFT+R, the browsers' hard reload).
    (bind "SUPER + ALT + R" "renameWorkspace" "Rename workspace")
    # Compact launcher, an ALT variant of SUPER+SPACE (DMS has it on ALT+SPACE, now dictation).
    (bind "SUPER + ALT + SPACE" "launcherBar" "Launcher bar")
    (bind "SUPER + CTRL + L" "lock" "Lock")
    (bind "SUPER + CTRL + I" "idleInhibit" "Toggle locking on idle")
    (bind "SUPER + CTRL + M" "miseTools" "mise tools panel")

    (bind "SUPER + CTRL + comma" "notifyInvoke" "Open latest notification")
    (bind "SUPER + ALT + comma" "notifyDismiss" "Dismiss latest notification")
    (bind "SUPER + SHIFT + comma" "notifyDismissAll" "Dismiss all notifications")
    (bind "SUPER + CTRL + ALT + comma" "notifyDnd" "Toggle Do Not Disturb")
    # Omarchy's notification history. The current dms/binds.lua has SUPER+N on the notepad
    # and the center on SUPER+CTRL+N, the network panel here, so this is its key.
    (bind "SUPER + SHIFT + ALT + comma" "notifyCenter" "Notification center")

    (locked (bind "SHIFT + XF86AudioMute" "audioOutputCycle" "Next audio output"))
    # Omarchy's track keys for keyboards without Next/Prev.
    (locked (bind "ALT + XF86AudioPlay" "mediaNext" "Next track"))
    (locked (bind "ALT + SHIFT + XF86AudioPlay" "mediaPrevious" "Previous track"))
    (bind "SUPER + SHIFT + space" "barToggle" "Toggle bar")

    (bind "SUPER + CTRL + SPACE" "wallpaperPicker" "Wallpaper picker")
    (bind "SUPER + CTRL + W" "wallpaperPicker" "Wallpaper picker")
    (bind "SUPER + CTRL + ALT + W" "wallhavenCarousel" "Wallhaven carousel")
    (bind "SUPER + CTRL + SHIFT + SPACE" "themePicker" "Theme picker")
    (bind "SUPER + CTRL + T" "themePicker" "Theme picker")

    (bind "SUPER + SPACE" "launcher" "Launcher")
    (bind "SUPER + comma" "settings" "Shell settings")
    (bind "ALT + Tab" "windowSwitcher" "Window switcher")
    (media (bind "XF86AudioRaiseVolume" "volumeUp" "Volume up"))
    (media (bind "XF86AudioLowerVolume" "volumeDown" "Volume down"))
    (locked (bind "XF86AudioMute" "volumeMute" "Mute"))
    (media (bind "XF86MonBrightnessUp" "brightnessUp" "Brightness up"))
    (media (bind "XF86MonBrightnessDown" "brightnessDown" "Brightness down"))
  ];
in
map (b: removeAttrs b [ "action" ] // { exec = commands.${b.action}; }) (
  lib.filter (b: commands ? ${b.action}) binds
)
