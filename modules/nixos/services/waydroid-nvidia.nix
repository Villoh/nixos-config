# Waydroid with NVIDIA GPU acceleration (candidate to benchmark against the AVD).
# Stock Waydroid falls back to SwiftShader (CPU) on NVIDIA; this swaps in the
# patched stack from Shiro836/waydroid-nvidia, packaged by yigexuanmu/waydroid-nvidia-nix.
#
# Uses the stock NixOS Waydroid module (gbinder, lxc, psi=1, firewall) with the
# patched package, plus the pieces upstream's own NixOS module adds.
#
# Nothing starts at boot. After `nh os test`:
#   sudo waydroid init
#   sudo waydroid-nvidia-setup --refresh <hz>
#   sudo systemctl start waydroid-container
#   systemctl --user start wd-venus
#   waydroid session start
# Verify GPU use: sudo waydroid shell dumpsys SurfaceFlinger | grep GLES
#   (must say "NVIDIA", not "SwiftShader").
#
# Trust: the guest stack is a prebuilt CI binary (SLSA-attested, hashes pinned
# by the packaging flake). The compositor must run on the NVIDIA GPU, so desktop only.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  wnv = inputs.waydroid-nvidia-nix.packages.${pkgs.stdenv.hostPlatform.system}.waydroid-nvidia-full;
  nvidia = config.hardware.nvidia;
in
{
  assertions = [
    {
      assertion = nvidia.open == true && nvidia.modesetting.enable;
      message = "waydroid-nvidia needs the NVIDIA open kernel modules with modesetting (DMA-BUF).";
    }
    {
      assertion = lib.versionAtLeast nvidia.package.version "595.71";
      message = "waydroid-nvidia needs NVIDIA driver 595.71 or newer (found ${nvidia.package.version}).";
    }
  ];

  virtualisation.waydroid = {
    enable = true;
    package = wnv;
  };

  # On demand only: the container service also trusts the waydroid0 bridge in
  # the firewall, so keep it off until measuring.
  systemd.services.waydroid-container.wantedBy = lib.mkForce [ ];

  # /dev/udmabuf access for the seated user, and the Venus socket directory.
  services.udev.packages = [ wnv ];
  systemd.tmpfiles.packages = [ wnv ];

  # Host-side Vulkan renderer the Android guest talks to over a unix socket.
  systemd.user.services.wd-venus = {
    description = "Venus vtest render server for waydroid-nvidia";
    serviceConfig = {
      ExecStart = "${wnv}/lib/waydroid-nvidia/virgl_test_server --venus --multi-clients --socket-path /run/waydroid-venus/venus.sock";
      Environment = [
        "RENDER_SERVER_EXEC_PATH=${wnv}/lib/waydroid-nvidia/virgl_render_server"
        "LD_LIBRARY_PATH=${wnv}/lib/waydroid-nvidia:${pkgs.vulkan-loader}/lib"
      ];
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
