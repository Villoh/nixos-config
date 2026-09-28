{ inputs, pkgs, ... }:

let
  nixMonitorConfig = pkgs.writeText "nix-monitor-config.json" (builtins.toJSON {
    generationsCommand = [
      "sh"
      "-c"
      "nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l"
    ];
    storeSizeCommand = [ "sh" "-c" "du -sh /nix/store 2>/dev/null | cut -f1" ];
    rebuildCommand = [
      "bash"
      "-c"
      "sudo nixos-rebuild test --flake /home/mikel/src/nixos-config#desktop 2>&1"
    ];
    gcCommand = [ "bash" "-c" "sudo nix-collect-garbage -d 2>&1" ];
    updateInterval = 300;
    localRevisionCommand = [ "sh" "-c" "nixos-version --hash 2>/dev/null | cut -c 1-7 || echo 'N/A'" ];
    remoteRevisionCommand = [
      "sh"
      "-c"
      "git ls-remote https://github.com/NixOS/nixpkgs.git nixos-unstable 2>/dev/null | cut -c 1-7 || echo 'N/A'"
    ];
    nixpkgsChannel = "nixos-unstable";
  });
  nixMonitorPlugin = pkgs.runCommand "nix-monitor-plugin" { } ''
    mkdir -p $out
    cp -r ${inputs.nix-monitor}/* $out/
    cp ${nixMonitorConfig} $out/config.json
  '';
in
{
  home-manager.users.mikel = {
    home.username = "mikel";
    home.homeDirectory = "/home/mikel";
    home.stateVersion = "26.05";

    home.file.".config/DankMaterialShell/plugins/NixMonitor".source = nixMonitorPlugin;

    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      # Keep the existing chezmoi-managed ~/.Xresources untouched.
      x11.enable = false;
    };
  };
}
