{ pkgs, ... }:

# NVIDIA eGPU over Thunderbolt/USB4 on a laptop whose iGPU (Intel) drives the
# desktop. Hosts select this explicitly; it is not part of the laptop profile.
#
# The eGPU can be absent at boot or unplugged at any time, so nothing here
# assumes a PCI bus ID (it changes with the port): cards are found by vendor
# and class through udev aliases. The initrd loads NVIDIA only when udev sees a card
# (see below), so an absent eGPU costs nothing there.
# Only nvidia_uvm is in boot.kernelModules; with no card present its load is
# expected to fail without effect (untested), and udev loads the driver when
# the card shows up.
{
  # Thunderbolt device authorisation. Enrol the enclosure once with
  # `boltctl enroll <uuid>`; other devices stay unauthorised. boltd is started
  # by a udev rule only when a Thunderbolt device appears, so this is inert
  # on OCuLink or with nothing plugged in and can stay enabled for either link.
  services.hardware.bolt.enable = true;

  # Keep the tunnel the firmware built. The default host reset drops it for ~1 s,
  # so nvidia probes a missing GPU in the initrd and fails 2-3 times before the link
  # returns. Untested: remove it if the eGPU stops authorising or enumerating.
  boot.kernelParams = [ "thunderbolt.host_reset=0" ];

  # Unplugging the eGPU while a monitor is lit on it wedges the NVIDIA driver
  # (Xid 79, pciehp stuck in nv_drm_remove, Hyprland in D state), see
  # NVIDIA/open-gpu-kernel-modules#1440 and #1190. There is no fix from userspace,
  # so reboot by itself instead of needing the power button: a task stuck in D state
  # for 120 s panics, and the kernel reboots 10 s later. Full SysRq (Alt+SysRq+S,U,B)
  # is the manual way out.
  # If the machine ever reboots like this without the eGPU hang, delete the
  # hung_task_panic line (and kernel.panic) and keep only sysrq. Check with:
  # journalctl -b -1 -k | grep -iE 'hung_task|Kernel panic'
  boot.kernel.sysctl = {
    "kernel.hung_task_panic" = 1;
    "kernel.panic" = 10;
    "kernel.sysrq" = 1;
  };

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

  # Plymouth and the LUKS prompt on the monitors wired to the eGPU. Two initrd-only
  # udev rules: authorize Thunderbolt devices when IOMMU DMA protection is on (the
  # kernel docs' rule, same policy boltd applies to "iommu" devices, which cannot run
  # in the initrd), then load nvidia_drm when an NVIDIA GPU appears. The modules are
  # only made available, not loaded: with no eGPU nothing fails or waits.
  boot.initrd.availableKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];
  boot.initrd.services.udev.rules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTRS{iommu_dma_protection}=="1", ATTR{authorized}=="0", ATTR{authorized}="1"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03*", RUN{builtin}+="kmod load nvidia_drm"
  '';

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
  # the next entry becomes primary when the first is unavailable). This is a
  # login-time fallback only: if the eGPU falls off the bus mid-session (Xid 79
  # on 2026-11-19) the session dies and the next login starts on the iGPU.
  # Attach the card before login: plugging it in later is untested, and
  # unplugging it during a session is not safe (see docs/installation-laptop.md).
  # Hyprland's Nvidia wiki lists AQ_FORCE_LINEAR_BLIT=0 (stop forcing linear
  # modifiers on multi-GPU buffers) for slow or broken multi-GPU. Left off
  # until measured on this hardware.
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

    # Detach the eGPU before pulling the cable. Run it from a text console (Ctrl+Alt+F3),
    # not inside Hyprland: Hyprland holds the NVIDIA driver (the eGPU is its primary
    # renderer), and removing a GPU the driver still has open stalls the driver, the same
    # wedge as pulling the cable (NVIDIA/open-gpu-kernel-modules#1440). So it ends the
    # graphical session first, refuses to continue if anything still has the card open,
    # removes the PCI functions, and brings the greeter back on the iGPU. Untested.
    (pkgs.writeShellApplication {
      name = "egpu-eject";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.psmisc
        pkgs.systemd
      ];
      text = ''
        [ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

        card=$(readlink -f /dev/dri/egpu) || { echo "no eGPU attached"; exit 1; }
        name=$(basename "$card")
        dev=$(readlink -f "/sys/class/drm/$name/device")
        bus=''${dev%.*}

        read -r -p "This ends the graphical session and removes $(basename "$dev"). Continue? [y/N] " ans
        [ "$ans" = y ] || exit 1

        # greetd's sessions live in their own logind scopes, so stopping greetd alone
        # would leave Hyprland running: end every Wayland session, then greetd.
        while read -r s _; do
          [ "$(loginctl show-session "$s" -p Type --value)" = wayland ] && loginctl terminate-session "$s"
        done < <(loginctl list-sessions --no-legend)
        systemctl stop greetd
        sleep 3

        shopt -s nullglob
        nodes=(/dev/nvidia* "$card")
        for r in /sys/class/drm/"$name"/device/drm/renderD*; do
          nodes+=("/dev/dri/$(basename "$r")")
        done
        if fuser -s "''${nodes[@]}" 2>/dev/null; then
          echo "Still in use, not removing:"
          fuser -v "''${nodes[@]}" 2>&1 || true
          systemctl start greetd
          exit 1
        fi

        for fn in "$bus".*; do
          echo 1 > "$fn/remove"
        done
        systemctl start greetd
        echo "eGPU removed. Safe to unplug the cable."
      '';
    })
  ];
}
