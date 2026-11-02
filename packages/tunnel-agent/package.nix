{
  appimageTools,
  fetchurl,
  icu,
  nix-update-script,
}:

let
  pname = "tunnel-agent";
  version = "1.1.12";
  src = fetchurl {
    url = "https://github.com/beyondhumane/tunnel-agent/releases/download/v${version}/TunnelAgent-${version}-linux-x64.AppImage";
    hash = "sha256-DRQN2BgmJTbKIaHh0hX8iSxeKDgwONbzZQWfNXMWKMg=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraPkgs = _: [ icu ];
  passthru.updateScript = nix-update-script { };
}
