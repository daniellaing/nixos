{ inputs, config, pkgs, lib, ... }:
with lib;
let
  cfg = config.programs.hyprpaper;
in
{
  options.programs.hyprpaper = {
    enable = mkEnableOption "Hyprpaper";
    package = mkPackageOption pkgs "hyprpaper" { };

    wallpaper = mkOption {
      type = types.path;
      description = "Path to your wallpaper";
      example = "~/.wallpaper.png";
    };
  };

  config = mkIf cfg.enable {
    home.packages = optional (cfg.package != null) cfg.package;
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${cfg.wallpaper}
      wallpaper = ,${cfg.wallpaper}
    '';
  };
}
