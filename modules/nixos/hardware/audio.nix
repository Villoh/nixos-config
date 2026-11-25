{ lib, pkgs, ... }:

{
  # Focusrite Scarlett mixer/routing GUI (kernel >= 6.8 already ships the scarlett2 driver).
  # pavucontrol: per-stream volume/routing UI, shows the video-capture loopback below.
  environment.systemPackages = [
    pkgs.alsa-scarlett-gui
    pkgs.pavucontrol
  ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Console (PS5) -> ezcap401 USB capture card -> Astro MixAmp Pro Chat (the MixAmp's USB Game channel stays
  # silent in PC mode). Control: systemctl --user stop|start|restart video-capture (restart also fixes a
  # stale link after the MixAmp re-enumerates). dont-fallback keeps the audio off the default sink while
  # either device is unplugged. shortcut: names hardcoded, parametrize if a 2nd capture card shows up.
  systemd.user.services.video-capture = {
    description = "Video capture audio loopback to Astro MixAmp";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" ];
    requires = [ "pipewire.service" ];
    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        "${pkgs.pipewire}/bin/pw-loopback"
        "-n"
        "video-capture"
        "-l"
        "43"
        "-C"
        "alsa_input.usb-ezc_ezcap401_EC4010001-02.analog-stereo"
        "-i"
        "{ node.dont-fallback=true }"
        "-P"
        "alsa_output.usb-Astro_Gaming_Astro_MixAmp_Pro-00.stereo-chat"
        "-o"
        # application.* makes the stream selectable in per-app audio pickers (Discord clients list streams by app name).
        "{ node.dont-fallback=true application.name=\"Video Capture\" application.process.binary=video-capture }"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
