{ ... }:

{
  virtualisation.docker.enable = true;
  users.users.mikel.extraGroups = [ "docker" ];
}
