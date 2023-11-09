{ config, pkgs, ... }:

{
  # Enable the KDE Plasma Desktop Environment.
  services.xserver = {
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = with pkgs; [ ]
    ++ builtins.filter lib.isDerivation (builtins.attrValues plasma5Packages.kdeGear)
    ++ builtins.filter lib.isDerivation (builtins.attrValues plasma5Packages.kdeFrameworks)
    ++ builtins.filter lib.isDerivation (builtins.attrValues plasma5Packages.plasma5);
}
