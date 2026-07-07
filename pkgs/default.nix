{pkgs ? import <nixpkgs> {}, ...}: rec {
  configure = pkgs.callPackage ./configure {};
  ffmd = pkgs.callPackage ./ffmd {};
  power-menu = pkgs.callPackage ./power-menu {};
  stag = pkgs.callPackage ./stag.nix {};
  update-system = pkgs.callPackage ./update-system {};
}
