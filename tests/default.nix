{
  inputs,
  system,
  desktop,
}:

let
  inherit (inputs.nixpkgs) lib;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  base = lib.nixosSystem {
    inherit system;
    modules = [
      ../modules/nixos/core
      ../profiles/desktop.nix
      {
        # Evaluation fixture, never an installable host or a real account.
        boot.isContainer = true;
        system.stateVersion = "26.05";
      }
    ];
  };
  multi = base.extendModules {
    modules = [
      ../modules/nixos/gaming
      inputs.home-manager.nixosModules.home-manager
      {
        users.users = {
          alice.isNormalUser = true;
          bob.isNormalUser = true;
        };
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users = {
            alice = {
              imports = [
                ../modules/home/shell/zsh.nix
                ../modules/home/desktop/dms-plugins.nix
                ../modules/home/gaming
              ];
              home.stateVersion = "26.05";
            };
            bob = {
              imports = [ ../modules/home/shell/zsh.nix ];
              home.stateVersion = "26.05";
            };
          };
        };
      }
    ];
  };
  c = base.config;
  m = multi.config;
  d = desktop.config;
  h = d.home-manager.users.mikel;
  names = packages: map lib.getName packages;
  systemNames = names c.environment.systemPackages;
  personalPackages = [
    "steam"
    "heroic"
    "hydralauncher"
    "lutris"
    "protonup-qt"
    "protonplus"
    "mangohud"
    "goverlay"
    "wine-wow64"
    "winetricks"
    "brave"
    "helium"
    "zen-browser"
  ];
  hasNoPersonalPackages =
    cfg: lib.intersectLists personalPackages (names cfg.environment.systemPackages) == [ ];
  normalUsers =
    cfg: builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) cfg.users.users);
in
{
  configuration-boundaries =
    assert lib.assertMsg (
      !(c ? home-manager) && normalUsers c == [ ]
    ) "Base must not need Home Manager or create personal accounts";
    assert lib.assertMsg (lib.all (name: builtins.elem name systemNames) [
      "ghostty"
      "nh"
      "hyprland"
      "dms-shell"
      "dsearch"
      "qtengine"
      "dms-hyprland-init"
    ]) "Desktop dependencies must be installed by NixOS";
    assert lib.assertMsg (lib.all hasNoPersonalPackages [
      c
      m
      d
    ]) "Personal applications leaked into systemPackages";
    assert lib.assertMsg (
      !builtins.elem "nvidia" c.services.xserver.videoDrivers
      && !builtins.elem "nvidia" c.boot.initrd.kernelModules
    ) "Generic desktop must not assume NVIDIA";
    assert lib.assertMsg (
      !c.virtualisation.docker.enable
      && !c.services.tailscale.enable
      && !c.services.printing.enable
      && !c.programs.kdeconnect.enable
    ) "Optional host services leaked into desktop base";
    assert lib.assertMsg (
      c.services.displayManager.dms-greeter.configHome == null
      && !(c.systemd.user.services.dms.environment ? TERMINAL)
    ) "DMS/greeter must not read a personal profile";
    assert lib.assertMsg (
      !(c.environment.etc ? "xdg/hypr/hyprland.lua") && !(c.environment.etc ? "xdg/hypr/dms-base.lua")
    ) "System Lua fallback must not eclipse personal legacy configurations";
    assert lib.assertMsg (
      normalUsers m == [
        "alice"
        "bob"
      ]
      && m.users.users.bob.extraGroups == [ ]
    ) "Second user must not inherit personal identity or privileges";
    assert lib.assertMsg (
      m.home-manager.users.alice.programs.zsh.dotDir != m.home-manager.users.bob.programs.zsh.dotDir
    ) "Reusable HM modules must derive per-user paths";
    assert lib.assertMsg (
      builtins.elem "steam" (names m.home-manager.users.alice.home.packages)
      && !builtins.elem "steam" (names m.home-manager.users.bob.home.packages)
    ) "Gaming must be selected per user";
    assert lib.assertMsg (
      !m.programs.steam.enable && m.hardware.steam-hardware.enable && m.hardware.graphics.enable32Bit
    ) "Steam integration must not install a global client";
    assert lib.assertMsg (
      d.home-manager.users.mikel.wayland.windowManager.hyprland.package == null
      && d.home-manager.users.mikel.wayland.windowManager.hyprland.portalPackage == null
    ) "Compositor packages belong to NixOS";
    assert lib.assertMsg (
      d.programs.dms-shell.plugins == { }
      && builtins.hasAttr "DankMaterialShell/plugins/bitwarden" h.xdg.configFile
      && builtins.hasAttr "DankMaterialShell/plugins/bitwarden" m.home-manager.users.alice.xdg.configFile
      && !(builtins.hasAttr "DankMaterialShell/plugins/bitwarden" m.home-manager.users.bob.xdg.configFile)
    ) "Personal DMS plugins must be per-user";
    assert lib.assertMsg (
      h.programs.dank-material-shell.enable
      && h.programs.dank-material-shell.package.outPath == d.programs.dms-shell.package.outPath
      && h.programs.quickshell.package.outPath == d.programs.dms-shell.quickshell.package.outPath
      && !h.programs.dank-material-shell.systemd.enable
      && !(h.systemd.user.services ? dms)
      && !(h.systemd.user.services ? quickshell)
    ) "The official HM module must reuse the host runtime without a second shell service";
    assert lib.assertMsg (
      !h.programs.dank-material-shell.managePluginSettings
      && lib.all (name: !(builtins.hasAttr "DankMaterialShell/${name}" h.xdg.configFile)) [
        "settings.json"
        "clsettings.json"
        "plugin_settings.json"
      ]
      && !(builtins.hasAttr "DankMaterialShell/session.json" h.xdg.stateFile)
    ) "DMS/chezmoi must retain ownership of personal settings and session state";
    assert lib.assertMsg (
      !d.home-manager.users.mikel.home.file."${d.home-manager.users.mikel.programs.gpg.homedir}/gpg-agent.conf".enable
    ) "Home Manager must not take over Mikel's chezmoi-owned GPG configuration";
    assert lib.assertMsg (
      lib.hasSuffix "--pinentry-program ${lib.getExe' d.home-manager.users.mikel.services.gpg-agent.pinentry.package d.home-manager.users.mikel.services.gpg-agent.pinentry.program}" (
        lib.concatStringsSep " " d.home-manager.users.mikel.systemd.user.services.gpg-agent.Service.ExecStart
      )
      && !d.programs.gnupg.agent.enable
    ) "The per-user GPG service must select pinentry even with a chezmoi-owned config";
    assert lib.assertMsg (
      !builtins.elem "gamemode" d.users.users.mikel.extraGroups
      && lib.hasPrefix "/nix/store/" d.home-manager.users.mikel.xdg.desktopEntries.tunnel-agent.exec
      &&
        d.home-manager.users.mikel.home.sessionVariables.AVALONIA_SCREEN_SCALE_FACTORS
        == "DP-1=1;HDMI-A-1=1.5"
    ) "Preserve existing privileges and the absolute Tunnel Agent wrapper";
    assert lib.assertMsg (
      c.services.displayManager.defaultSession == "hyprland-uwsm"
      && !c.systemd.user.services."wayland-wm@".restartIfChanged
    ) "Use the initialized UWSM session without restarting an active compositor on rebuild";
    builtins.deepSeq [ c.system.build.toplevel.drvPath m.system.build.toplevel.drvPath ] (
      pkgs.runCommand "configuration-boundaries" { } ''touch "$out"''
    );

  greeter-cache =
    let
      prepare = pkgs.writeShellScript "greeter-cache-prestart" c.systemd.services.greetd.preStart;
      syncPrepare = pkgs.writeShellScript "greeter-home-prestart" d.systemd.services.greetd.preStart;
      syncHook =
        settings:
        (base.extendModules {
          modules = [ { services.displayManager.dms-greeter = settings; } ];
        }).config.systemd.services.greetd.preStart;
      cacheDir = d.systemd.tmpfiles.settings."10-dms-greeter"."/var/lib/dms-greeter".d;
    in
    assert lib.assertMsg (
      c.systemd.services.greetd.preStart == ""
      && !(c.systemd.services.greetd.serviceConfig ? ExecStartPre)
      && cacheDir.user == "dms-greeter"
      && cacheDir.group == "dms-greeter"
      && cacheDir.mode == "0750"
    ) "Cache-only greeter must skip sync while retaining directory provisioning";
    assert lib.assertMsg (
      lib.hasInfix "/test-greeter-home/.config/DankMaterialShell/settings.json" (syncHook {
        configHome = lib.mkForce "/test-greeter-home";
      })
      && lib.hasInfix "/test-greeter-settings.json" (syncHook {
        configFiles = [ "/test-greeter-settings.json" ];
      })
    ) "Explicit greeter sync sources must retain the upstream preparation hook";
    assert lib.assertMsg (
      d.services.displayManager.dms-greeter.configHome == d.users.users.mikel.home
      && lib.hasInfix "${d.users.users.mikel.home}/.config/DankMaterialShell/settings.json" (
        d.systemd.services.greetd.preStart
      )
      && d.systemd.services.greetd.serviceConfig ? ExecStartPre
    ) "Desktop must import Mikel's appearance through the native greeter hook";
    pkgs.runCommand "greeter-cache" { } ''
      # Relocate the real hook, never execute it against /var/lib or a real HOME.
      cache="$TMPDIR/greeter-cache"
      mkdir -p "$cache"
      sed "s|/var/lib/dms-greeter|$cache|g" ${prepare} > "$TMPDIR/prepare"
      bash -e "$TMPDIR/prepare"

      printf '{}\n' > "$cache/custom-theme.json"
      printf '{"customThemeFile":"%s/custom-theme.json"}\n' "$cache" > "$cache/settings.json"
      printf '{}\n' > "$cache/colors.json"
      snapshot() {
        (cd "$cache"; find . -type f -print0 | sort -z | xargs -0 sha256sum)
      }
      snapshot > "$TMPDIR/before"
      bash -e "$TMPDIR/prepare"
      bash -e "$TMPDIR/prepare"
      snapshot > "$TMPDIR/after"
      cmp "$TMPDIR/before" "$TMPDIR/after"

      printf 'cached wallpaper\n' > "$cache/wallpaper"
      printf 'cached monitor wallpaper\n' > "$cache/wallpaper-monitor-DP-1-"
      printf '{"wallpaperPath":"%s/wallpaper","monitorWallpapers":{"DP-1":"%s/wallpaper-monitor-DP-1-"}}\n' \
        "$cache" "$cache" > "$cache/session.json"
      snapshot > "$TMPDIR/before"
      bash -e "$TMPDIR/prepare"
      bash -e "$TMPDIR/prepare"
      snapshot > "$TMPDIR/after"
      cmp "$TMPDIR/before" "$TMPDIR/after"

      # Real desktop hook, with all sources/destinations relocated to fixtures.
      home="$TMPDIR/home"
      mkdir -p "$home/.config/DankMaterialShell" \
        "$home/.local/state/DankMaterialShell" "$home/.cache/DankMaterialShell"
      printf '{"theme":"first"}\n' > "$home/theme.json"
      printf 'personal wallpaper\n' > "$home/wallpaper"
      printf '{"customThemeFile":"%s/theme.json"}\n' "$home" \
        > "$home/.config/DankMaterialShell/settings.json"
      printf '{"wallpaperPath":"%s/wallpaper"}\n' "$home" \
        > "$home/.local/state/DankMaterialShell/session.json"
      printf '{"color":"first"}\n' > "$home/.cache/DankMaterialShell/dms-colors.json"
      (cd "$home"; find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$TMPDIR/home-before"
      sed "s|/var/lib/dms-greeter|$cache|g;s|${d.users.users.mikel.home}|$home|g" \
        ${syncPrepare} > "$TMPDIR/sync"
      bash -e "$TMPDIR/sync"
      bash -e "$TMPDIR/sync"
      cmp "$home/theme.json" "$cache/custom-theme.json"
      cmp "$home/wallpaper" "$cache/wallpaper"
      cmp "$home/.cache/DankMaterialShell/dms-colors.json" "$cache/colors.json"
      ${lib.getExe pkgs.jq} -e --arg path "$cache/custom-theme.json" \
        '.customThemeFile == $path' "$cache/settings.json"
      ${lib.getExe pkgs.jq} -e --arg path "$cache/wallpaper" \
        '.wallpaperPath == $path' "$cache/session.json"
      (cd "$home"; find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$TMPDIR/home-after"
      cmp "$TMPDIR/home-before" "$TMPDIR/home-after"

      # UI changes are picked up on the next greetd start, not watched live.
      printf '{"theme":"second"}\n' > "$home/theme.json"
      printf 'new personal wallpaper\n' > "$home/wallpaper"
      bash -e "$TMPDIR/sync"
      cmp "$home/theme.json" "$cache/custom-theme.json"
      cmp "$home/wallpaper" "$cache/wallpaper"
      touch "$out"
    '';

  gaming-session =
    let
      sessionPackage = lib.findFirst (
        p: builtins.elem "steam" (p.providedSessions or [ ])
      ) null m.services.displayManager.sessionPackages;
    in
    pkgs.runCommand "gaming-session" { } ''
      session=$(sed -n 's/^Exec=//p' ${sessionPackage}/share/wayland-sessions/steam.desktop)
      mkdir -p "$TMPDIR/home" "$TMPDIR/wrappers"
      if HOME="$TMPDIR/home" PATH="${pkgs.coreutils}/bin" "$session"; then
        echo "A user without Steam must not launch the gaming session" >&2
        exit 1
      fi

      mkdir -p "$TMPDIR/home/.nix-profile/bin"
      printf '#!${pkgs.runtimeShell}\nexit 0\n' > "$TMPDIR/home/.nix-profile/bin/steam"
      cat > "$TMPDIR/wrappers/gamescope" <<'SH'
      #!${pkgs.runtimeShell}
      set -eu
      test "$*" = '--steam -- steam -tenfoot -pipewire-dmabuf'
      test "$(command -v steam)" = "$HOME/.nix-profile/bin/steam"
      echo wrapper > "$RESULT"
      SH
      chmod +x "$TMPDIR/home/.nix-profile/bin/steam" "$TMPDIR/wrappers/gamescope"
      HOME="$TMPDIR/home" PATH="$TMPDIR/wrappers:${pkgs.coreutils}/bin" RESULT="$TMPDIR/result" "$session"
      test "$(cat "$TMPDIR/result")" = wrapper
      touch "$out"
    '';

  dms-session =
    pkgs.runCommand "dms-session"
      {
        nativeBuildInputs = [
          pkgs.jq
          c.programs.dms-shell.package
          c.programs.hyprland.package
        ];
        PRE_START =
          pkgs.writeShellScript "dms-session-prestart"
            c.systemd.user.services."wayland-wm@".preStart;
        PERSONAL_CONFIG = d.home-manager.users.mikel.xdg.configFile."hypr/hyprland.lua".source;
        HOST_CONFIG = d.environment.etc."xdg/hypr/host.lua".source;
      }
      ''
        bash ${./dms-session.sh}
        touch "$out"
      '';
}
