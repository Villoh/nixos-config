{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./display.nix
    ../../modules/nixos/core
    ../../profiles/desktop.nix
    ../../profiles/gaming.nix
    ../../users/mikel
    inputs.home-manager.nixosModules.home-manager
  ];

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "mikel";
    };
    defaultSession = "hyprland";
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
  };
}
