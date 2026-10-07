{ ... }:

{
  # Desk monitors, matched by EDID description so the layout follows them
  # through any port or dock. Away from the desk no rule matches and the
  # internal panel keeps Hyprland/DMS defaults. Merged with keyboard.nix; the
  # greeter already requires this file.
  environment.etc."xdg/hypr/host.lua".text = ''
    -- ASUS VG259QM on the left, Acer VG280K on the right, bottoms aligned.
    hl.monitor({
      output = "desc:ASUSTek COMPUTER INC VG259QM L9LMQS194060",
      mode = "1920x1080@239.760",
      position = "0x0",
      scale = 1,
    })
    hl.monitor({
      output = "desc:Acer Technologies VG280K 0x0431B372",
      mode = "3840x2160@59.997",
      position = "1920x-360",
      scale = 1.5,
    })
  '';
}
