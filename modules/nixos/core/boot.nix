{ ... }:

{
  boot = {
    consoleLogLevel = 3;
    # The initrd is systemd's (nixpkgs dropped the scripted one and initrd.verbose):
    # rd.systemd.show_status and rd.udev.log_level below keep it quiet.
    kernelParams = [
      "quiet"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
  };

  # Reported working themes (last three not boot-tested here).
  # - ed7ed: add flake input; set themePackages to inputs.nixos-plymouth-theme.packages.<system>.default; theme = "nixos".
  #   https://github.com/ed7ed/nixos-plymouth-theme
  # - Owl: themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "owl" ]; }) ]; theme = "owl".
  #   https://github.com/adi1090x/plymouth-themes
  # - paulchambaz: fetchFromGitHub + pkgs.callPackage; theme = "nixos-load".
  #   https://github.com/paulchambaz/nixos-plymouth
  # - Material: add flake input + nixosModules.material; theme = "material"; enable boot.initrd.systemd.
  #   https://github.com/krozzzis/plymouth-theme-material
  # - nixos-boot: add flake input + nixosModules.default; set nixos-boot.enable = true; theme = "load_unload" or "evil-nixos" (bloats the initrd up to ~50 MB; prompt anchored to the bottom of the canvas, so with mixed-size monitors it can fall off the smaller one).
  #   https://github.com/Melkor333/nixos-boot
  # - mac-style: add flake input + overlays.default; themePackages = [ pkgs.mac-style-plymouth ]; theme = "mac-style" (two-step module, fixed-size images; needs acidBoot.enable = false).
  #   https://github.com/SergioRibera/s4rchiso-plymouth-theme
  # - Acid Boot: add flake input + nixosModules.default; set acidBoot.enable = true (custom Plymouth/systemd integration).
  #   https://github.com/kurisu-agent/nix-acid-boot
}
