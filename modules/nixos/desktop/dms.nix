{ inputs, pkgs, ... }:

{
  # Provides the AT-SPI2 accessibility bus required by Pi computer-use.
  services.gnome.at-spi2-core.enable = true;

  programs.dms-shell = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
    plugins = {
      pkgUpdate.src = pkgs.fetchFromGitHub {
        owner = "rahulmysore23";
        repo = "dms-pkg-update";
        rev = "a17dd21f6f72582ede70646db9d0eefc302d05bc";
        hash = "sha256-c0d0urqMo/2O1sDTj48beiv3qWHRpFnBctc1PzKz6pw=";
      };
      quickCapture.src = pkgs.fetchFromGitHub {
        owner = "hthienloc";
        repo = "dms-quick-capture";
        rev = "d84703fb9b1ae20c3870130fca4dae9a6b57b5c0";
        hash = "sha256-cb+IvVl2/i31qIwhIKVTY3GhYn1G0zwGPAEqVrXhRTY=";
      };
      bitwarden.src = pkgs.fetchFromGitHub {
        owner = "coldi1337";
        repo = "dms-bitwarden-cli";
        rev = "a3ddbe852d5e96e60164234ef84e67d19aa8caf1";
        hash = "sha256-axePK7+Icv6jhxpGEfFGIJ05Ug168yXI1NDQ/1NK5CQ=";
      };
    };
  };

  environment.systemPackages = [
    pkgs.dgop
    pkgs.dsearch
    inputs.dankcalendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
