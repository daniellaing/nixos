{pkgs ? import <nixpkgs> {}, ...}: {
  default = {
    commands = [
      {package = "nh";}
      {package = "configure";}
      {package = "update-system";}
    ];
  };

  configure = pkgs.mkShell {
    shellHook = ''exec $SHELL'';
  };
}
