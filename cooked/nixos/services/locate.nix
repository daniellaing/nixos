{
  lib,
  config,
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
      pruneBindMounts = true;
    };
  };
}
