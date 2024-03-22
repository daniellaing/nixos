{
  config,
  pkgs,
  lib,
  ...
}: let
  m = let
    wrapped = pkgs.writeShellScriptBin "mathematica" ''
      rm -f ''${MATHEMATICA_USERBASE:-$HOME/.Mathematica}/Autoload/PacletManager/Configuration/FrontEnd/init_${pkgs.stable.mathematica.version}.0.m
      exec ${pkgs.stable.mathematica}/bin/mathematica "$@"
    '';
  in
    pkgs.symlinkJoin {
      name = "mathematica";
      paths = [
        wrapped
        pkgs.stable.mathematica
      ];
    };
in {
  environment = {
    systemPackages = [m];
    variables = {
      QT_XCB_GL_INTEGRATION = "none";
    };
  };
}
