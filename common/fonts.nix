{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.fonts;
in {
  options.fonts = {
    enable = lib.mkEnableOption ''
      Enable added fonts
    '';
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        nerdfonts
      ];
    };
  };
}
