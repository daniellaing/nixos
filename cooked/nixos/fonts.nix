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
      packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };
  };
}
