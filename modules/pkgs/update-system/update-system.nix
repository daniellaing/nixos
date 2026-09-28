{...}: let
  name = "update-system";
in {
  perSystem = {pkgs, ...}: {
    packages.${name} = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        git
        libnotify
        nh
      ];
      text = builtins.readFile ./update-system.sh;
    };
  };
}
