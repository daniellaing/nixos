{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.locate;
in {
  options.locate = {
    enable = lib.mkEnableOption ''
      Enable file locate package
    '';
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
