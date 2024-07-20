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

  config = lib.mkIf cfg.enable {};

  imports = [
    ./display-manager.nix
  ];
}
