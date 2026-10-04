{ ... }:

{
  imports = [ ./account.nix ];
  home-manager.users.mikel = import ./home.nix;
}
