{ config, pkgs, lib, ... }:
let
  c = config.xdg.configHome;
  d = config.xdg.dataHome;
  p = pkgs.writeShellScript "dl-ls" ''
    ${pkgs.lsd}/bin/lsd -v --group-dirs first $* && echo "$(${pkgs.lsd}/bin/lsd $* | wc -l) items"
  '';
in
{
  imports = [
    ./terminal.nix
    ./zsh.nix
    ./editor.nix
  ];

  home = {
    shellAliases = import ./aliases.nix;
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
