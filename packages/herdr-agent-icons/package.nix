{
  lib,
  stdenvNoCC,
  fetchurl,
  python3Packages,
}:

# Icon font that herdr-agent-usage draws its agent logos with (Private Use Area U+E1A0-E1C5).
# The plugin copies the same file into ~/.local/share/fonts on `configure`; installing it
# from Nix keeps it declarative. Sheprd selects it through `fallback` in its config.
# gpui (Sheprd) drops any font without an 'm' glyph as broken, which silently empties the
# fallback list; the icon font has only 29 glyphs, so an empty 'm' is added below.
# Pinned to the plugin commit that ships it; the file's sha256 starts with the d77910ea
# the plugin puts in its file name, so it only changes when the font itself does.
stdenvNoCC.mkDerivation {
  pname = "herdr-agent-icons";
  version = "0-unstable-2026-11-08";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/levi-qiao/herdr-agent-quota/18144990e6beead4be5a93002601b96fe3b66ba2/assets/fonts/HerdrAgentIconsMax-Regular.ttf";
    hash = "sha256-13kQ6k5wqG5GGLpTKfUYMPObgwR3wfuAnepwTswZn2Y=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ python3Packages.fonttools ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    python3 - $src $out/share/fonts/truetype/HerdrAgentIconsMax-Regular.ttf <<'EOF'
    import sys
    from fontTools.ttLib import TTFont
    from fontTools.ttLib.tables._g_l_y_f import Glyph
    f = TTFont(sys.argv[1])
    cmap = f.getBestCmap()
    assert 0x6D not in cmap
    adv = f["hmtx"][cmap[0xE1A0]][0]
    f.setGlyphOrder(f.getGlyphOrder() + ["m"])
    f["glyf"]["m"] = Glyph()
    f["hmtx"]["m"] = (adv, 0)
    for t in f["cmap"].tables:
        t.cmap[0x6D] = "m"
    f.save(sys.argv[2])
    EOF
    runHook postInstall
  '';

  meta = {
    description = "Agent logo icon font for herdr-agent-usage";
    homepage = "https://github.com/levi-qiao/herdr-agent-quota";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
