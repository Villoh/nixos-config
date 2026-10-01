{ ... }:

{
  # Acid Boot needs NVIDIA DRM available in initrd for the LUKS splash.
  boot.initrd.kernelModules = [ "nvidia" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };
}
