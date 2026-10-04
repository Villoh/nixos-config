{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  # Reuse nixpkgs' host-aware graphics/FHS wrapper without enabling the global
  # Steam module. Only this user's wrapper discovers this user's Proton tools.
  steam = osConfig.programs.steam.package.override (previous: {
    extraEnv = (previous.extraEnv or { }) // {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = lib.makeSearchPathOutput "steamcompattool" "" [
        pkgs.proton-ge-bin
      ];
    };
  });
in
{
  assertions = [
    {
      assertion = osConfig.hardware.steam-hardware.enable && osConfig.hardware.graphics.enable32Bit;
      message = "The Home Manager gaming profile needs modules/nixos/gaming on this host.";
    }
  ];
  home.packages = [
    steam
    steam.run
  ];
}
