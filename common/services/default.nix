{
  lib,
  config,
  ...
}: let
  cfg = config.services;
in {
  options.services = {
    enable = lib.mkEnableOption ''
      Enable services
    '';
  };

  config = lib.mkIf cfg.enable {
    locate.enable = lib.mkDefault true;
  };

  imports = [
    ./display-manager.nix
    ./locate.nix
  ];
}
