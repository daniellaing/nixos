{ pkgs }:

pkgs.writeShellScriptBin "editor" ''
    ${pkgs.neovim}/bin/nvim "$@"
  # ${pkgs.neovide}/bin/neovide --multigrid "$@"
''
