{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    layout = "gb";
    xkbVariant = "";
  };

  environment.systemPackages = with pkgs; [
    xclip
    dmenu
  ];

}
