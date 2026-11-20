{ config, pkgs, ... }:

{
  # Generate this host's hardware-configuration.nix on the Zenbook before
  # adding this host to flake.nix. Do not reuse desktop hardware settings.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    # The RTX 3080 moves to a Thunderbolt eGPU; the Arc iGPU drives the desktop.
    ../../modules/nixos/hardware/egpu-nvidia.nix
    ../../modules/nixos/hardware/monitor-input.nix
    ../../modules/nixos/hardware/logitech-receiver.nix
    # Optional desktop services, selected by this host rather than the profile.
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/printing.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/kdeconnect.nix
    ../../profiles/laptop.nix
    ../../users/mikel
    ../../users/mikel/al68.nix
    ../../modules/nixos/home-manager.nix
    ./display.nix
    ./keyboard.nix
    # Acid Boot with the relayout patch for the eGPU monitors; replaces the input's own module.
    ../../modules/nixos/hardware/acid-boot-egpu.nix
  ];

  networking.hostName = "nixos-zenbook";
  system.stateVersion = "26.05";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };

  # Unlocks the swap partition declared in hardware-configuration.nix; the installer
  # kept this entry in /etc/nixos/configuration.nix, which the flake does not import.
  boot.initrd.luks.devices."luks-ad6ce096-c480-4d2f-84e7-551d22c89eae".device =
    "/dev/disk/by-uuid/ad6ce096-c480-4d2f-84e7-551d22c89eae";

  # Hibernate (S4) so the dock NIC can wake the laptop from a full power-off; swap is the
  # LUKS partition above, unlocked in the initrd before resume runs.
  boot.resumeDevice = "/dev/mapper/luks-ad6ce096-c480-4d2f-84e7-551d22c89eae";

  acidBoot = {
    enable = true;
    palette = "nix-blue";
  };

  # Early KMS for the Arc iGPU: without it Plymouth draws on simpledrm (the UEFI
  # framebuffer) and the LUKS prompt can come out stretched. mei_gsc_proxy must load
  # with it, or i915 waits 20 s for the GSC proxy and logs "GSC proxy component didn't
  # bind within the expected timeout".
  boot.initrd.kernelModules = [
    "i915"
    "mei_me"
    "mei_gsc_proxy"
  ];

  users.users.mikel.extraGroups = [ "docker" ];

  # Intel thermal daemon (Core Ultra); works alongside power-profiles-daemon.
  services.thermald.enable = true;

  # Wake-on-LAN (magic packet) on the dock's USB NIC. Matched by driver, not name: the
  # enp0s13f0u1u4u2 name follows the USB port path and changes if the dock moves port.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", DRIVERS=="r8152", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
  '';

  # One shared login appearance, imported by nixpkgs before greetd starts. Missing
  # source files (fresh home) are skipped, so the greeter keeps its defaults.
  services.displayManager.dux-greeter.configHome = config.users.users.mikel.home;
}
