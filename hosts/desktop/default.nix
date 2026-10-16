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
    ../../modules/nixos/services/docker.nix
    # Optional desktop services, selected by this host rather than the profile.
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/printing.nix
    ../../profiles/desktop.nix
    ../../profiles/gaming.nix
    ../../users/mikel
    inputs.home-manager.nixosModules.home-manager
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

  services.tailscale.enable = true;
  programs.kdeconnect.enable = true;

  users.groups.al68 = { };
  users.users.mikel.extraGroups = [
    "docker"
    "al68"
  ];

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
    dms-greeter.configHome = config.users.users.mikel.home;
  };

  services.udev.extraRules = ''
    # Let Chromium/WebHID access YUNZII AL68 for VIA configuration.
    KERNEL=="hidraw*", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="304e", TAG+="uaccess", GROUP="al68", MODE="0660"

    # The Logitech receiver (046d:c547) cuts S3 short: with its wake enabled, sleep
    # usually ended after ~3 s with no input (ACPI GPE 0x08, the shared PCIe PME),
    # also with the mouse off. With it disabled, or the receiver unplugged, the PC
    # stayed asleep until the AL68 keyboard woke it (tested up to ~30 s). Root
    # cause unknown; the same symptom is reported for Logitech Bolt receivers
    # (LKML, 2026-08-10). Trade-off: the Logitech mouse no longer wakes the PC.
    # Matched by vendor:product, so it follows the receiver across USB ports (the
    # kernel name, e.g. 1-3.1, is the physical port and changes). The receiver has
    # no serial number, so any other 046d:c547 receiver gets the same rule.
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="046d", ATTR{idProduct}=="c547", ATTR{power/wakeup}="disabled"
  '';

  home-manager = {
    # Preserve pre-existing user files when Home Manager first takes ownership.
    backupFileExtension = "bak";
    # Apps (DMS, Brave, xdg-mime) rewrite files like mimeapps.list; Nix wins and
    # the last app-written version stays in <file>.bak instead of blocking activation.
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.mikel = {
      imports = [ ../../modules/home/gaming ];

      # Avalonia is X11-only; with force_zero_scaling it needs per-output scale.
      home.sessionVariables.AVALONIA_SCREEN_SCALE_FACTORS = "DP-1=1;HDMI-A-1=1.5";

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        -- Keep workspace 1 on DP-1 and workspace 6 on HDMI-A-1.
        hl.workspace_rule({
          workspace = "1",
          monitor = "DP-1",
          default = true,
        })
        hl.workspace_rule({
          workspace = "6",
          monitor = "HDMI-A-1",
          default = true,
        })
      '';
    };
  };
}
