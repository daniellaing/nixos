{ config, pkgs, ... }:

{
  imports = [
    ./browser.nix
    ./git.nix
    ./music.nix
    ./picom.nix
    ./R.nix
    ./rofi.nix
    ./sxhkd.nix
    ./sxiv.nix
    ./syncthing.nix
    ./xdg.nix
    ./zathura.nix
  ];
}
