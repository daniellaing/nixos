{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.locate;
in {
  options.cooked.locate = {
    enable = lib.mkEnableOption "plocate";
  };

  config = lib.mkIf cfg.enable {
    services.locate = {
      enable = true;
      interval = "hourly";
      package = pkgs.plocate;
      pruneBindMounts = true;
      localuser = null;
    };
  };
}
