{
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

# Flatpak bundle consumed by nix-flatpak (modules/home/communication/packages.nix).
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "flectar-mail";
  version = "0.1.0-alpha.7";

  src = fetchurl {
    url = "https://github.com/flectar/mail/releases/download/v${finalAttrs.version}/flectar-mail-${finalAttrs.version}-linux-x64.flatpak";
    hash = "sha256-tDlFa59TaEylVGSi+w1YuK7eXd8eDrT4Hm4l66s6b5U=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm644 "$src" "$out/share/flatpak/flectar-mail.flatpak"
  '';

  # Upstream only publishes alpha tags; the default "stable" filter would skip them.
  passthru.updateScript = nix-update-script { extraArgs = [ "--version=unstable" ]; };

  meta.homepage = "https://github.com/flectar/mail";
})
