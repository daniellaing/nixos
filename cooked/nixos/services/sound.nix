{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.sound;
in {
  imports = [../../../modules/XF86.nix];

  options.cooked.sound = {
    enable = lib.mkEnableOption ''sound'';
  };

  config = lib.mkIf cfg.enable {
    XF86 = {
      audioLowerVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      audioMute = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      audioRaiseVolume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
    };

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
  };
}
