{
  config,
  inputs,
  lib,
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
  ];

  networking.hostName = "nixos";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
    # Remember the last selected OS/generation instead of each new build.
    systemd-boot.extraInstallCommands = ''
      ${config.systemd.package}/bin/bootctl set-default @saved
    '';
    efi.canTouchEfiVariables = true;
  };

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

  # Let Chromium/WebHID access YUNZII AL68 for VIA configuration.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="304e", TAG+="uaccess", GROUP="al68", MODE="0660"
  '';

  home-manager = {
    # Preserve pre-existing user files when Home Manager first takes ownership.
    backupFileExtension = "bak";
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
