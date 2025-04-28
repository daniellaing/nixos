{pkgs ? import <nixpkgs> {}, ...}: {
  default = {
    devshell = {
      name = "hello";
      packages = builtins.attrValues {
        inherit (pkgs) nh;
      };
    };
  };
}
