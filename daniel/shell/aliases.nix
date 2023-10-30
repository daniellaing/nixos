{ config, pkgs, ... }:
let
  dl_ls = pkgs.writeShellScriptBin "dl-ls" ''
    ${pkgs.lsd}/bin/lsd -v --group-dirs first $* && echo "$(${pkgs.lsd}/bin/lsd $* | wc -l) items"
  '';
in
{
  ls = "${dl_ls} ";
  sudo = "sudo ";
  la = "ls -A";
  ll = "ls -lA";
  grep = "grep --color=auto ";
  fgrep = "fgrep --color=auto ";
  egrep = "egrep --color=auto ";
  diff = "diff --color=auto ";
  ip = "ip --color=auto ";
  python = "${pkgs.python3}/bin/python3 ";
  v = "$EDITOR ";
  cp = "cp -v ";
  rm = "rm -v ";
  mv = "mv -iv ";
  mkdir = "mkdir -vp ";
  h = "fc -l 1 | grep ";
  email = "sync-email && neomutt ";

  tree = "${pkgs.lsd}/bin/lsd --tree ";
  cat = "${pkgs.bat}/bin/bat --theme=gruvbox-dark  --pager=never ";
  less = "${pkgs.bat}/bin/bat ";
}
