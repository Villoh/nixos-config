{ config, ... }:

let
  mounts = "/run/media/${config.users.users.mikel.name}";
in
{
  # Permite a Strata y Nautilus detectar, desbloquear y montar unidades mediante UDisks.
  services.udisks2.enable = true;
  # GIO/GVfs para Strata y Nautilus; también instala las reglas udev MTP.
  services.gvfs.enable = true;
  security.polkit.enable = true;
  # VeraCrypt monta junto a los demás discos, en /run/media/<usuario>/veracrypt<N>. Solo crea el
  # último componente, así que /run/media/<usuario> (tmpfs, lo crea udisks al primer disco) debe existir.
  environment.sessionVariables.VERACRYPT_MOUNT_PREFIX = "${mounts}/veracrypt";
  systemd.tmpfiles.rules = [ "d ${mounts} 0750 ${config.users.users.mikel.name} users -" ];
}
