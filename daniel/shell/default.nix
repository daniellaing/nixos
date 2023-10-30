{ config, pkgs, ... }:

{
  home = {
    shellAliases = {
      sudo = "sudo ";
      la = "ls -A";
      ll = "ls -lA";
      grep = "grep --color=auto ";
      fgrep = "fgrep --color=auto ";
      egrep = "egrep --color=auto ";
      diff = "diff --color=auto ";
      ip = "ip --color=auto ";
      python = "python3 ";
      v = "$EDITOR ";
      cp = "cp -v ";
      rm = "rm -v ";
      mv = "mv -iv ";
      mkdir = "mkdir -vp ";
      h = "fc -l 1 | grep ";
      email = "sync-email && neomutt ";

      ls = "dl-ls ";
      tree = "${pkgs.lsd}/bin/lsd --tree ";
      cat = "${pkgs.bat}/bin/bat --theme=gruvbox-dark  --pager=never ";
      less = "${pkgs.bat}/bin/bat ";
    };

    sessionVariables = {
      EDITOR = "editor";
      SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
      BROWSER = "${pkgs.librewolf}/bin/librewolf";
      TERMINAL = "${pkgs.alacritty}/bin/alacritty";

      LESSHISTFILE = "-";
      CARGO_HOME = "${config.xdg.dataHome}/cargo";

      # TeX
      TEXMFHOME = "${config.xdg.dataHome}/texmf";
      TEXMFVAR = "${config.xdg.cacheHome}/texlive/texmf-var";
      TEXMFCONFIG = "${config.xdg.configHome}/texlive/texmf-config";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.xdg.dataHome}/cargo/bin"
    ];

    packages = with pkgs; [
      (import ./editor.nix { inherit pkgs; })
      (import ./dl-ls.nix { inherit pkgs; })
    ];
  };
}
