{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./state.nix
    ./display.nix
    ../../modules/nixos/core
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/hardware/astro-mixamp.nix
    ../../modules/nixos/hardware/logitech-receiver.nix
    ../../modules/nixos/hardware/usb-oc.nix
    ../../modules/nixos/services/docker.nix
    # Optional desktop services, selected by this host rather than the profile.
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/kdeconnect.nix
    # NVIDIA-only: the compositor must run on the NVIDIA GPU (not the zenbook).
    ../../modules/nixos/services/waydroid-nvidia.nix
    ../../profiles/desktop.nix
    ../../profiles/gaming.nix
    ../../users/mikel
    ../../users/mikel/al68.nix
    ../../modules/nixos/home-manager.nix
    inputs.acid-boot.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  networking.hostName = "nixos";

  # Secure Boot via Lanzaboote (replaces the stock systemd-boot installer but
  # keeps the systemd-boot menu). Keys live in /var/lib/sbctl and must exist
  # before the first rebuild. See docs/secure-boot.md.
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
  };
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 5;
  };
  environment.systemPackages = [ pkgs.sbctl ];

  users.users.mikel.extraGroups = [ "docker" ];

  acidBoot = {
    enable = true;
    palette = "nix-blue";
  };

  services.displayManager = {
    # Temporarily disabled while diagnosing the UWSM session startup.
    # autoLogin = {
    #   enable = true;
    #   user = "mikel";
    # };
    defaultSession = "hyprland-uwsm";
    # One shared login appearance, imported by nixpkgs before greetd starts.
    dux-greeter.configHome = config.users.users.mikel.home;
  };

  home-manager = {
    users.mikel = {
      imports = [ ../../modules/home/gaming ];

      # Avalonia is X11-only; with force_zero_scaling it needs per-output scale.
      home.sessionVariables.AVALONIA_SCREEN_SCALE_FACTORS = "DP-1=1.5;HDMI-A-1=1.5";

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        -- Workspaces 1-5 on DP-1, 6-10 on HDMI-A-1 (an unpinned workspace opens on
        -- the focused monitor).
        for i = 1, 10 do
          hl.workspace_rule({
            workspace = tostring(i),
            monitor = i <= 5 and "DP-1" or "HDMI-A-1",
            default = i == 1 or i == 6,
          })
        end
      '';
    };
  };
}
