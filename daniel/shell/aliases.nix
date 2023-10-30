{ config, pkgs, ... }:

{
  sudo = "sudo ";

  ls = "${lib.getBin p} ";
  la = "ls -A";
  ll = "ls -lA";

  grep = "grep --color=auto ";
  fgrep = "fgrep --color=auto ";
  egrep = "egrep --color=auto ";
  diff = "diff --color=auto ";
  ip = "ip --color=auto ";
  tree = "${pkgs.lsd}/bin/lsd --tree ";
  cat = "${pkgs.bat}/bin/bat --theme=gruvbox-dark  --pager=never ";
  less = "${pkgs.bat}/bin/bat ";

  python = "${pkgs.python3}/bin/python3 ";

  v = "$EDITOR ";

  cp = "cp -v ";
  rm = "rm -v ";
  mv = "mv -iv ";
  mkdir = "mkdir -vp ";
  h = "fc -l 1 | grep ";

  email = "sync-email && neomutt ";
}
