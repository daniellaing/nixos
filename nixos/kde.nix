{
  pkgs,
  lib,
  ...
}: {
  # Enable the KDE Plasma Desktop Environment.
  services.xserver = {
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages =
    builtins.filter lib.isDerivation (builtins.attrValues pkgs.plasma5Packages.kdeGear)
    ++ builtins.filter lib.isDerivation (builtins.attrValues pkgs.plasma5Packages.kdeFrameworks)
    ++ builtins.filter lib.isDerivation (builtins.attrValues pkgs.plasma5Packages.plasma5);
}
