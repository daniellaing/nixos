{ config, pkgs, ... }:
let
  c = config.xdg.configHome;
  d = config.xdg.dataHome;
  dl_ls = pkgs.writeShellScriptBin "dl-ls" ''
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
    packages = [ dl_ls ];
    shellAliases =
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
      };

    sessionVariables = {
      BROWSER = "${pkgs.librewolf}/bin/librewolf";
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";

      LESSHISTFILE = "-";
      CARGO_HOME = d + "/cargo";

      # TeX
      TEXMFHOME = d + "/texmf";
      TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
      TEXMFCONFIG = c + "/texlive/texmf-config";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.xdg.dataHome}/cargo/bin"
    ];
  };
}
