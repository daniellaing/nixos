{pkgs ? import <nixpkgs> {}, ...}: {
  default = {
    devshell = {
      name = "hello";
      packages = builtins.attrValues {
        inherit (pkgs) nh configure update-system;
      };
    };
  };

  configure.devshell.name = "NixOS configuration shell";
}
