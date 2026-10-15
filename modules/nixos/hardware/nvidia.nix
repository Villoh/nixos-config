{ ... }:

{
  # Acid Boot needs NVIDIA DRM available in initrd for the LUKS splash.
  boot.initrd.kernelModules = [ "nvidia" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    # Save VRAM to /var/tmp across S3 suspend. Without it, resume left the GPU
    # contexts corrupt (Xid 13) and Hyprland aborted on 2026-10-15.
    powerManagement.enable = true;
  };
}
