{ config, ... }:

{
  # Host capability only: Steam and Proton are selected in Home Manager.
  # Keep programs.steam.enable off: it would install a global Steam client.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.steam-hardware.enable = true;
  services.pulseaudio.support32Bit = config.services.pulseaudio.enable;
  services.pipewire.alsa.support32Bit = config.services.pipewire.alsa.enable;

  # The upstream package option supplies the host's graphics libraries even
  # when the global module is disabled; retain its normal font integration.
  programs.steam.extraPackages = config.programs.steam.fontPackages;
}
