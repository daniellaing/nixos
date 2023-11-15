{ stable-pkgs, config, pkgs, lib, ... }:

{
  home.packages = with stable-pkgs; let
    m = pkgs.writeScriptBin "mathematica" ''
      rm ~/.Mathematica/Autoload/PacletManager/Configuration/FrontEnd/init_${mathematica.version}.0.m
      exec ${lib.getBin mathematica}/bin/mathematica "$@"
    '';
  in
  [
    mathematica
    m
  ];

  home.sessionVariables.MATHEMATICA_USERBASE = "${config.xdg.configHome}/mathematica";
}
