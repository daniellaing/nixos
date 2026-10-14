{...}: let
  name = "powermenu";
in {
  perSystem = {pkgs, ...}: {
    packages.${name} = pkgs.writeShellApplication {
      name = "powermenu";
      runtimeInputs = with pkgs; [
        wofi
        waylock
        hyprland
      ];
      text = builtins.readFile ./power-menu.sh;
    };
  };
}
