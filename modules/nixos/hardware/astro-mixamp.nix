{ ... }:

# Opt-in per host: lets mikel open the ASTRO MixAmp Pro (9886:0038) HID node without
# root, for Astro Command Center under Wine. Audio is unaffected; it only needs this
# for the EQ/settings channel.
{
  # OWNER instead of TAG+="uaccess": extraRules land in 99-local.rules, after
  # 73-seat-late.rules has already processed uaccess, so that tag does nothing.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="9886", ATTRS{idProduct}=="0038", OWNER="mikel", MODE="0660"
  '';
}
