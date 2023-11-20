{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; let
    m = writeScriptBin "mathematica" ''
      rm ~/.Mathematica/Autoload/PacletManager/Configuration/FrontEnd/init_${mathematica.version}.0.m
      exec ${lib.getBin mathematica}/bin/mathematica "$@"
    '';
  in
  [
    mathematica
    m
  ];
}
