{ config, pkgs, ... }:

{
  imports = [
    ./browser.nix
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
