{ config, pkgs, ... }:

{
  home = {
    username = "daniel";
    homeDirectory = "/home/daniel";
    stateVersion = "23.05";
    packages = with pkgs; [
      btop
      ferdium
      musescore
      yt-dlp
      nnn
      keepassxc
      librewolf
    ];
  };

  imports =
    [
      ./shell
      ./email
      ./programs
    ];

  # Let home manager manage itself
  programs.home-manager.enable = true;
}
