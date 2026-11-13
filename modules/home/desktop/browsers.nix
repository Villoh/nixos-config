{
  inputs,
  pkgs,
  ...
}:

let
  # Icon themes (Colloid, Papirus...) ship `brave` but not `brave-origin`, so the
  # launcher trims the name and shows the regular Brave logo. Use an absolute path.
  brave-origin = pkgs.brave-origin.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace $out/share/applications/*.desktop \
        --replace-fail "Icon=brave-origin" \
        "Icon=$out/share/icons/hicolor/256x256/apps/brave-origin.png"
    '';
  });
in
{
  home.packages = [
    brave-origin
    inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium
  ];
}
