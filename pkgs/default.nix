{pkgs ? import <nixpkgs> {}, ...}: rec {
  configure = pkgs.callPackage ./configure {};
  update-system = pkgs.callPackage ./update-system {};

  power-menu = pkgs.callPackage ./power-menu {};
}
