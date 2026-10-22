{config, ...}: {
  modules.sound = {
    lib,
    pkgs,
    ...
  }: {
    imports = with config.modules; [xf86];

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      audio.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        pulsemixer
        pavucontrol
        ;
    };

    home-manager.sharedModules = [
      {
        xf86 = {
          audioLowerVolume.cmd = "${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          audioMute.cmd = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          audioRaiseVolume.cmd = "${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        };
      }
    ];
  };
}
