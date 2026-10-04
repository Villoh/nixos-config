{ ... }:

{
  boot = {
    consoleLogLevel = 3;
    initrd.verbose = false;
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
  # - Acid Boot: add flake input + nixosModules.default; set acidBoot.enable = true (custom Plymouth/systemd integration).
  #   https://github.com/kurisu-agent/nix-acid-boot
}
