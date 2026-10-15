{ ... }:

{
  # Permite a Dolphin detectar, desbloquear y montar unidades mediante UDisks.
  services.udisks2.enable = true;
  # GIO/GVfs para Strata; también instala las reglas udev MTP para Dolphin.
  services.gvfs.enable = true;
  security.polkit.enable = true;
}
