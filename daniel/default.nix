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
      ./xdg.nix

      ./shell

      ./email
      ./music.nix

      ./git.nix
      ./picom.nix
      ./rofi.nix
      ./sxhkd.nix
      ./syncthing.nix
      ./zathura.nix
    ];

  # Let home manager manage itself
  programs.home-manager.enable = true;
}
