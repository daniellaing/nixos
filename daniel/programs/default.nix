{
  imports = [
    ./browsers
    ./dunst.nix
    ./music.nix
    ./picom.nix
    ./syncthing.nix
    ./yazi.nix
    ./zathura.nix

    # Wayland
    ./wayland/waybar.nix
    ./wayland/hyprland.nix
    ./wayland/wofi.nix
  ];
}
