{ pkgs, ... }:

# NVIDIA eGPU over Thunderbolt/USB4 on a laptop whose iGPU (Intel) drives the
# desktop. Hosts select this explicitly; it is not part of the laptop profile.
#
# The eGPU can be absent at boot or unplugged at any time, so nothing here
# assumes a PCI bus ID (it changes with the port): cards are found by vendor
# and class through udev aliases, and nothing loads NVIDIA from the initrd.
# Only nvidia_uvm is in boot.kernelModules; with no card present its load is
# expected to fail without effect (untested), and udev loads the driver when
# the card shows up.
{
  # Thunderbolt device authorisation. Enrol the enclosure once with
  # `boltctl enroll <uuid>`; other devices stay unauthorised. boltd is started
  # by a udev rule only when a Thunderbolt device appears, so this is inert
  # on OCuLink or with nothing plugged in and can stay enabled for either link.
  services.hardware.bolt.enable = true;

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    # Ampere (RTX 30) and newer: the open kernel modules are supported.
    open = true;
    # Same fix as desktop: keep VRAM across S3 so resume does not corrupt the GPU.
    powerManagement.enable = true;
  };

  services.udev.extraRules = ''
    # Stable aliases for Hyprland. The class match matters: on Thunderbolt the
    # eGPU sits behind an Intel PCIe bridge, so a vendor-only rule would also
    # tag the eGPU as the iGPU.
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", ATTRS{class}=="0x03*", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x10de", ATTRS{class}=="0x03*", SYMLINK+="dri/egpu"
  '';

  # The first available entry is Hyprland's primary renderer. With the eGPU
  # attached at login it renders the desktop, so games and monitors wired to it
  # skip the link; without it Hyprland falls back to the iGPU (Hyprland wiki:
  # the next entry becomes primary when the first is unavailable). Attach the
  # card before login: plugging it in later is untested, and unplugging it
  # during a session is not safe (see docs/installation-laptop.md).
  # Hyprland's Nvidia wiki lists these for slow or broken multi-GPU: swap the
  # order above, and AQ_FORCE_LINEAR_BLIT=0 (stop forcing linear modifiers on
  # multi-GPU buffers). Left off until measured on this hardware.
  environment.etc."xdg/uwsm/env-hyprland".text = ''
    export AQ_DRM_DEVICES=/dev/dri/egpu:/dev/dri/igpu
    # export AQ_FORCE_LINEAR_BLIT=0
    # uwsm sources this file as shell. With the eGPU attached at login, make every
    # Vulkan/GL program use it, so games need no wrapper. Without it, set nothing.
    if [ -e /dev/dri/egpu ]; then
      export __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia
    fi
  '';

  # Run one program on the eGPU: nvidia-offload <program>. Same variables as
  # NVIDIA's PRIME render offload README and the Arch wiki. Only needed when the
  # session variables above are not set (eGPU attached after login).
  # Hyprland's primary GPU does not decide where an application renders:
  # Vulkan and GL pick their own device.
  # Do not set __EGL_VENDOR_LIBRARY_FILENAMES globally to avoid NVIDIA EGL: the
  # Omarchy hybrid-GPU notes report that it breaks Hyprland's own EGL start-up.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      exec "$@"
    '')
  ];
}
