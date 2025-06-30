{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.dbus;
in {
  options.cooked.dbus.enable = lib.mkEnableOption "dbus configuration";

  config = lib.mkIf cfg.enable {
    services.dbus.packages = [
      pkgs.dbus.out
      config.system.path
      pkgs.pinentry-curses
    ];
    environment.pathsToLink = ["/etc/dbus-1" "/share/dbus-1"];
  };
}
