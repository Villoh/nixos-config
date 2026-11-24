{ lib, pkgs, ... }:

let
  # pkexec drops WAYLAND_DISPLAY/XDG_RUNTIME_DIR and DISPLAY, so root GUIs either fail to
  # start (XWayland rejects root) or fall back to unscaled X11 (xwayland.force_zero_scaling).
  # Pass the Wayland socket through and force native Wayland for Qt (and GTK).
  gui-root = pkgs.writeShellScriptBin "gui-root" ''
    exec /run/wrappers/bin/pkexec ${pkgs.coreutils}/bin/env \
      WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
      GDK_BACKEND=wayland QT_QPA_PLATFORM=wayland \
      PATH=/run/current-system/sw/bin "$@"
  '';

  # QDiskInfo needs root for smartctl. Same name as the package's launcher, so its
  # .desktop entry (Exec=QDiskInfo) picks this one up.
  qdiskinfo-root = lib.hiPrio (
    pkgs.writeShellScriptBin "QDiskInfo" ''
      exec ${gui-root}/bin/gui-root ${pkgs.qdiskinfo}/bin/QDiskInfo "$@"
    ''
  );
in
{
  # CrystalDiskInfo equivalents: QDiskInfo (GUI), gnome-disks (SMART + self-tests, no root),
  # smartctl / nvme (CLI).
  # CrystalDiskMark equivalent: KDiskMark (fio frontend). Its privileged helper is a
  # system D-Bus service, so the package must be registered with dbus and polkit.
  programs.gnome-disks.enable = true;
  services.dbus.packages = [ pkgs.kdiskmark ];

  environment.systemPackages = with pkgs; [
    gui-root
    qdiskinfo-root
    qdiskinfo # GUI S.M.A.R.T. (closest to CrystalDiskInfo: same layout, health badge, themes)
    smartmontools # smartctl CLI
    nvme-cli # nvme smart-log, NVMe wear/temps
    kdiskmark # GUI benchmark (closest to CrystalDiskMark)
    fio # CLI benchmark engine
  ];
}
