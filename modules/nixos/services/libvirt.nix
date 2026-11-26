{ pkgs, ... }:

# libvirt + QEMU/KVM with virt-manager as the desktop app for VMs, and virt-viewer for just the
# console (SPICE/VNC: works before Windows boots, unlike RDP). swtpm gives Windows 11 a TPM; OVMF
# (UEFI) comes with the libvirt module. The user needs the libvirtd group (set by the host).
# After `nh os test`, check the NAT network: `virsh -c qemu:///system net-list --all`, and start it
# with `virsh -c qemu:///system net-start default` (+ `net-autostart default`) if it is missing.
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  programs.virt-manager.enable = true;
  environment.systemPackages = [ pkgs.virt-viewer ];
}
