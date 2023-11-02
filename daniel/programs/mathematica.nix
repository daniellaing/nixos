{ config, pkgs, ... }:

{
  home.sessionVariables.MATHEMATICA_USERBASE = "${config.xdg.configHome}/mathematica";
}
