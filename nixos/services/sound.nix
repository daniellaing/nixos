{
  pkgs,
  lib,
  ...
}: let
  # Dependencies
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
in {
  imports = [../../modules/XF86.nix];

  XF86 = {
    audioLowerVolume = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    audioMute = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
    audioRaiseVolume = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    audio.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pulsemixer
    pavucontrol
  ];
}
