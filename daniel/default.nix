{ config, pkgs, ... }:

{
  home.username = "daniel";
  home.homeDirectory = "/home/daniel";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    btop
    ferdium
    musescore
    yt-dlp
  ];

  imports =
    [
      ./xdg.nix

      ./shell
      ./zsh.nix

      ./email
      ./music.nix

      ./alacritty.nix
      ./git.nix
      ./picom.nix
      ./rofi.nix
      ./sxhkd.nix
      ./syncthing.nix
      ./zathura.nix
    ];

  services.gnome-keyring.enable = true;
}
