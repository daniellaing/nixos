{
  users.daniel.modules.shell-aliases = {
    lib,
    pkgs,
    ...
  }: let
    p = pkgs.writeShellScript "dl-ls" ''
      ${pkgs.lsd}/bin/lsd -v --group-dirs first $* && echo "$(${pkgs.lsd}/bin/lsd $* | wc -l) items"
    '';
  in {
    home-manager.users.daniel.home.shellAliases = {
      sudo = "sudo ";

      ls = "${lib.getBin p} ";
      la = "ls -A";
      ll = "ls -lA";

      grep = "${pkgs.ripgrep}/bin/rg ";
      egrep = "${pkgs.ripgrep}/bin/rg ";
      diff = "diff --color=auto ";
      ip = "ip --color=auto ";
      tree = "${pkgs.lsd}/bin/lsd --tree ";
      cat = "${pkgs.bat}/bin/bat --theme=gruvbox-dark  --pager=never ";
      less = "${pkgs.bat}/bin/bat ";

      v = "$EDITOR ";

      cp = "cp -v ";
      rm = "rm -v ";
      mv = "mv -iv ";
      mkdir = "mkdir -vp ";
      h = "fc -l 1 | grep ";

      email = "neomutt ";
    };
  };
}
