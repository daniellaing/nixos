{pkgs ? import <nixpkgs> {}, ...}: {
  default = {
    commands = [
      {package = "nh";}
      {package = "configure";}
      {package = "update-system";}
    ];
  };

  configure = {
    devshell.startup = [
      {text = "exec $SHELL";}
    ];
  };
}
