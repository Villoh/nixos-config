{ config, lib, pkgs, ... }:

let
  kernel = config.boot.kernelPackages.kernel;

  # VID:PID:bInterval, one entry per device (see lsusb for the IDs).
  overrides = [
    "054c:0ce6:1" # DualSense
  ];

  # Out-of-tree equivalent of Windows' hidusbf: rewrites bInterval on a USB
  # device's interrupt endpoints. usbhid's jspoll ignores gamepads, so this
  # avoids patching and rebuilding the kernel.
  usb-oc = pkgs.stdenv.mkDerivation {
    pname = "usb_oc";
    version = "1.1-unstable-2026-11";

    src = pkgs.fetchFromGitHub {
      owner = "p0358";
      repo = "usb_oc-dkms";
      rev = "8f0bc17820387aa81567595d426f9bfeae891bde";
      hash = "sha256-TrFvZfa55+ZoxIdnphCqz1CcX1OYKCCMWeQ0wC/Nvas=";
    };

    nativeBuildInputs = kernel.moduleBuildDependencies;

    # Kbuild's own modules_install signs the module and writes the usb_oc.ko.cer
    # that aggregateModules expects; a plain `install` of the .ko leaves it out.
    makeFlags = config.boot.kernelPackages.kernelModuleMakeFlags ++ [
      "-C"
      "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "M=$(PWD)"
      "INSTALL_MOD_PATH=${placeholder "out"}"
      "DEPMOD=true"
    ];
    buildFlags = [ "modules" ];
    installTargets = [ "modules_install" ];

    meta.license = pkgs.lib.licenses.gpl2Only;
  };
in
{
  boot.extraModulePackages = [ usb-oc ];
  boot.kernelModules = [ "usb_oc" ];

  # Do NOT pass this as a modprobe option: usb_oc kcalloc()s in its param setter,
  # and on 6.18 module args are parsed before the module's alloc-profiling
  # counters exist, so a load-time value oopses. Writing it at runtime is fine.
  #
  # VID:PID:bInterval. DualSense is high-speed: period = 2^(bInterval-1) * 125 us,
  # so 1 = 8000 Hz, 2 = 4000 Hz, 3 = 2000 Hz, 4 = 1000 Hz (stock). USB only.
  # Change at runtime (re-enumerates the device) with:
  #   echo -n '054c:0ce6:2' | sudo tee /sys/module/usb_oc/parameters/interrupt_interval_override
  systemd.services.usb-oc = {
    description = "Apply usb_oc interrupt interval overrides";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo -n ${lib.concatStringsSep "," overrides} > /sys/module/usb_oc/parameters/interrupt_interval_override
    '';
  };
}
