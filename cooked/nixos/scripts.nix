{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.scripts;
in {
  options.cooked.scripts = {
    enable = lib.mkEnableOption "scripts";
    nix-helpers = lib.mkEnableOption "nix helper scrips";
    menus = lib.mkEnableOption "menus";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.lists.optionals cfg.nix-helpers builtins.attrValues {inherit (pkgs) configure update-system;}
      ++ lib.lists.optionals cfg.menus [
        pkgs.power-menu
      ];
  };
}
