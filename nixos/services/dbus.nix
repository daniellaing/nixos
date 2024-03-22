{
  config,
  pkgs,
  ...
}: {
  services.dbus.packages = [
    pkgs.dbus.out
    config.system.path
  ];
  environment.pathsToLink = ["/etc/dbus-1" "/share/dbus-1"];
}
