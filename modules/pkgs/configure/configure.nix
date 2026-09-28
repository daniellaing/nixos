{...}: let
  name = "configure";
in {
  perSystem = {pkgs, ...}: {
    packages.${name} =
      pkgs.writeShellApplication
      {
        inherit name;
        runtimeInputs = with pkgs; [
          alejandra
          git
          libnotify
          nh
        ];
        text = builtins.readFile ./configure.sh;
      };
  };
}
