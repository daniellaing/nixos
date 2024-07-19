{
  lib,
  config,
  ...
}: let
  cfg = config.network;
in {
  options.network = {
    enable = lib.mkEnableOption ''
      Enable networking
    '';
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      nftables.enable = true;
    };
  };
}
