{ pkgs, ... }:

{
  # Focusrite Scarlett mixer/routing GUI (kernel >= 6.8 already ships the scarlett2 driver).
  environment.systemPackages = [ pkgs.alsa-scarlett-gui ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
