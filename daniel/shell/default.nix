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
      CARGO_HOME = d + "/cargo";

      # TeX
      TEXMFHOME = d + "/texmf";
      TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
      TEXMFCONFIG = c + "/texlive/texmf-config";
    };

    sessionPath = [
      "${config.xdg.dataHome}/cargo/bin"
    ];
  };
}
