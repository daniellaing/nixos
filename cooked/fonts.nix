{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.cooked.fonts;
in {
  options.cooked.fonts = {
    enable = lib.mkEnableOption "added fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = builtins.attrValues {
        inherit
          (pkgs)
          nerdfonts
          ;
      };
    };
  };
}
