{ config, pkgs, lib, ... }@inputs:
let
  c = config.xdg.configHome;
  d = config.xdg.dataHome;
in
{
  imports = [
    ./terminal.nix
    ./zsh.nix
    ./editor.nix
  ];

  home = {
    shellAliases = import ./aliases.nix (inputs);
    sessionVariables = {
      LESSHISTFILE = "-";
      XCOMPOSEFILE = c + "/X11/xcompose";
      XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";

      # TeX
      TEXMFHOME = d + "/texmf";
      TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
      TEXMFCONFIG = c + "/texlive/texmf-config";

      # Mathematica
      MATHEMATICA_USERBASE = c + "/mathematica";

      # Cargo
      CARGO_HOME = d + "/cargo";

      # CUDA
      CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    };
  };
}
