{ pkgs, ... }:

let
  cliproxyapi = pkgs.cliproxyapi.overrideAttrs (_: {
    version = "8.0.3";
    src = pkgs.fetchFromGitHub {
      owner = "router-for-me";
      repo = "CLIProxyAPI";
      rev = "v8.0.3";
      hash = "sha256-1LrRpPkteIzBpwIdxFpA9WupwryRBoVt4jO/T8Dzgng=";
    };
    vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";
  });
in
{
  home-manager.users.mikel.home.packages = [ cliproxyapi ];
}
