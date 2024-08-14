{
  lib,
  config,
  ...
}: let
  cfg = config.cooked.network;
in {
  options.cooked.network = {
    enable = lib.mkEnableOption "networking";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;
      nftables.enable = true;
    };
  };
}
