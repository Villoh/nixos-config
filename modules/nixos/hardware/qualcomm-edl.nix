{ ... }:

# Opt-in per host: lets mikel open Qualcomm EDL (9008) devices without root
# (bkerler/edl, QFIL). Inert unless a phone is in EDL mode.
{
  # OWNER instead of TAG+="uaccess": extraRules land in 99-local.rules, after
  # 73-seat-late.rules has already processed uaccess, so that tag does nothing.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="05c6", ATTRS{idProduct}=="9008", OWNER="mikel", MODE="0660"
  '';
}
