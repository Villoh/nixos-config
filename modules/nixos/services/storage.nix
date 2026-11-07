{ ... }:

{
  # Permite a Strata y Nautilus detectar, desbloquear y montar unidades mediante UDisks.
  services.udisks2.enable = true;
  # GIO/GVfs para Strata y Nautilus; también instala las reglas udev MTP.
  services.gvfs.enable = true;
  security.polkit.enable = true;
}
