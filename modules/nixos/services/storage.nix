{ ... }:

{
  # Permite a Dolphin detectar, desbloquear y montar unidades mediante UDisks.
  services.udisks2.enable = true;
  security.polkit.enable = true;
}
