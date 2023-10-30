{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    cycle = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
  };
}
