{
  hyprland,
  waylock,
  wofi,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "powermenu";
  runtimeInputs = [
    wofi
    waylock
    hyprland
  ];
  text = builtins.readFile ./power-menu.sh;
}
