{ config, pkgs, ... }:

{
  imports = [

    ./browser.nix
    ./git.nix
    ./mathematica.nix
    ./mpv.nix
    ./music.nix
    ./picom.nix
    ./R.nix
    ./syncthing.nix
    ./xdg.nix
    ./zathura.nix

    # X11
    ./X11/rofi.nix
    ./X11/sxhkd.nix
    ./X11/sxiv.nix

    # Wayland
    ./wayland/waybar.nix
    ./wayland/hyprland.nix
    ./wayland/wofi.nix
  ];
}
