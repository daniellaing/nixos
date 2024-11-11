{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./browsers
    ./dunst.nix
    ./git.nix
    ./lf.nix
    ./mpv.nix
    ./music.nix
    ./picom.nix
    ./syncthing.nix
    ./xdg.nix
    ./yazi.nix
    ./zathura.nix

    # Wayland
    ./wayland/waybar.nix
    ./wayland/hyprland.nix
    ./wayland/wofi.nix
  ];
}
