{ pkgs }:

pkgs.writeShellScriptBin "dl-ls" ''
  ${pkgs.lsd}/bin/lsd -v --group-dirs first $* && echo "$(${pkgs.lsd}/bin/lsd $* | wc -l) items"
''
