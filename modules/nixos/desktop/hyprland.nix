{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Seed writable user files from the pinned DMS, not a second custom keymap.
  defaults = pkgs.runCommand "dms-hyprland-defaults" { } ''
    mkdir -p "$out"
    for name in colors layout outputs cursor windowrules binds; do
      cp ${config.programs.dms-shell.package.src}/core/internal/config/embedded/hypr-$name.lua "$out/$name.lua"
    done
    substituteInPlace "$out/binds.lua" \
      --replace-fail '{{TERMINAL_COMMAND}}' 'xdg-terminal-exec'
  '';
  mainConfig = pkgs.writeText "hyprland.lua" (
    builtins.readFile ./hyprland-base.lua
    + ''
      require("/etc/xdg/hypr/host")
    ''
  );
  initialize = pkgs.writeShellApplication {
    name = "dms-hyprland-init";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
      main="$config_dir/hyprland.lua"
      legacy="$config_dir/hyprland.conf"

      # Do not create a Lua main that would eclipse an existing legacy config.
      if [[ ! -e "$main" && ! -L "$main" ]] && [[ -e "$legacy" || -L "$legacy" ]]; then
        exit 0
      fi

      umask 077
      mkdir -p "$config_dir/dms"
      for name in colors layout outputs cursor windowrules binds; do
        target="$config_dir/dms/$name.lua"
        # Empty files and dangling symlinks are existing user choices too.
        if [[ ! -e "$target" && ! -L "$target" ]]; then
          cp --update=none --no-preserve=mode -T "${defaults}/$name.lua" "$target"
        fi
      done
      if [[ ! -e "$main" && ! -L "$main" ]]; then
        cp --update=none --no-preserve=mode -T ${mainConfig} "$main"
      fi
    '';
  };
in
{
  programs.hyprland = {
    enable = true;
    # UWSM is the sole owner of the compositor and graphical-session.target.
    withUWSM = true;
    xwayland.enable = true;
  };

  services.displayManager.defaultSession = lib.mkDefault "hyprland-uwsm";

  environment.systemPackages = [ initialize ];
  environment.etc."xdg/hypr/host.lua".text = lib.mkDefault "";

  # UWSM prepares the user's environment before this template runs. Seed only
  # Hyprland sessions, before the compositor (and therefore before DMS starts).
  systemd.user.services."wayland-wm@".preStart = ''
    case ":''${XDG_CURRENT_DESKTOP:-}:" in
      *:Hyprland:*|*:hyprland:*) ${lib.getExe initialize} ;;
    esac
  '';
}
