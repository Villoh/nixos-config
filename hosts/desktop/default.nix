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
  '';

  # The Logitech receiver (046d:c547) cut S3 short: with its wake enabled, sleep
  # ended after ~3 s with no input (ACPI GPE 0x08, the shared PCIe PME), but only
  # if the mouse was moved in the 5 min before suspending.
  # Likely cause: after wireless input the receiver queues data on USB interface
  # 2 (hiddev, unread); when the port suspends it raises a remote wakeup ~3 s
  # later. HID_QUIRK_ALWAYS_POLL (0x400) makes usbhid always read it; same fix as
  # the Bolt (c548) one, lore.kernel.org
  # 20260407-logi-bolt-hid-quirk-always-poll-v1-1-4dae0fda344e@collabora.com.
  # Checked on this machine (kernel 6.18.55): sleep holds and the mouse wakes the
  # PC. One Bolt user still hit the bug with it on 7.1.6 (LKML, 2026-08-10).
  # If the PC wakes by itself after ~3 s again, fall back to a udev rule:
  #   ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device",
  #   ATTR{idVendor}=="046d", ATTR{idProduct}=="c547", ATTR{power/wakeup}="disabled"
  # (matches by vendor:product, so it survives USB port changes; the mouse then
  # no longer wakes the PC).
  boot.kernelParams = [ "usbhid.quirks=0x046d:0xc547:0x400" ];

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
