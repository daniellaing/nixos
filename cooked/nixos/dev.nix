{
  lib,
  config,
  ...
}: let
  cfg = config.cooked.dev;
in {
  options.cooked.dev = {
    enable = lib.mkEnableOption "development tools";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      silent = true;
    };
  };
}
