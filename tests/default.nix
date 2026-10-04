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
          users = {
            alice = {
              imports = [
                ../modules/home/shell/zsh.nix
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
      && builtins.hasAttr "DankMaterialShell/plugins/bitwarden" d.home-manager.users.mikel.xdg.configFile
    ) "Personal DMS plugins must be per-user";
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
