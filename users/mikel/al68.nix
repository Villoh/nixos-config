{ ... }:

# Opt-in per host: import it where the YUNZII AL68 keyboard is plugged in.
{
  users.groups.al68 = { };
  users.users.mikel.extraGroups = [ "al68" ];

  services.udev.extraRules = ''
    # Let Chromium/WebHID access YUNZII AL68 for VIA configuration.
    KERNEL=="hidraw*", ATTRS{idVendor}=="4d4b", ATTRS{idProduct}=="304e", TAG+="uaccess", GROUP="al68", MODE="0660"
  '';
}
