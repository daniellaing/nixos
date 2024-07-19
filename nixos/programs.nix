{pkgs, ...}: let
  pypkgs = ps:
    builtins.attrValues {
      inherit
        (ps)
        numpy
        requests
        pandas
        pip
        ;
    };
in {
  environment.systemPackages =
    builtins.attrValues {
      inherit
        (pkgs)
        # Utility
        
        git
        gcc
        unzip
        wget
        ripgrep
        gnumake
        pinentry-curses
        gnupg
        # (uutils-coreutils.override {prefix = "";}) # Coreutils rewrite in Rust btw
        
        # Secret management
        
        sops
        # Desktop
        
        libreoffice
        firefox
        # Wayland
        
        wl-clipboard
        ;
    }
    ++ [
      pkgs.texlive.combined.scheme-full
      (pkgs.uutils-coreutils.override {prefix = "";}) # Coreutils rewrite in Rust btw
      (pkgs.python3.withPackages pypkgs)
    ];
}
