{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./music.nix
    ./picom.nix
    ./rofi.nix
    ./sxhkd.nix
    ./syncthing.nix
    ./xdg.nix
    ./zathura.nix
  ];
}
