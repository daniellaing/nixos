{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.hyprpaper;
in {
  options.programs.hyprpaper = {
    enable = lib.mkEnableOption "Hyprpaper";
    package = lib.mkPackageOption pkgs "hyprpaper" {};

    wallpaper = lib.mkOption {
      type = lib.types.path;
      description = "Path to your wallpaper";
      example = "~/.wallpaper.png";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${cfg.wallpaper}
      wallpaper = ,${cfg.wallpaper}
    '';
  };
}
