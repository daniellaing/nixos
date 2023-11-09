{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
  };

  # Emergency terminal
  environment.systemPackages = [
    pkgs.kitty
  ];
}
