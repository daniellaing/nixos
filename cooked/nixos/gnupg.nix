{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.gnupg;
in {
  options.cooked.gnupg = {
    enable = lib.mkEnableOption "gnupg";
  };

  config = lib.mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };
}
