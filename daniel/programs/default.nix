{ config, pkgs, ... }:

{
  imports = [

    ./browsers
    ./dunst.nix
    ./git.nix
    ./lf.nix
    ./mpv.nix
    ./music.nix
    ./picom.nix
    ./R.nix
    ./syncthing.nix
    ./xdg.nix
    ./zathura.nix

    # Wayland
    ./wayland/waybar.nix
    ./wayland/hyprland.nix
    ./wayland/wofi.nix
  ];
}
