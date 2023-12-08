{ pkgs, ... }:
let
  pypkgs = ps: with ps; [
    numpy
    requests
    pandas
    pip
  ];
in
{
  environment.systemPackages = with pkgs; [
    # Utility
    git
    gcc
    unzip
    wget
    ripgrep
    gnumake
    pinentry-curses
    gnupg
    (uutils-coreutils.override { prefix = ""; }) # Coreutils rewrite in Rust btw

    # Secret management
    sops

    # Development
    (python3.withPackages pypkgs)
    texlive.combined.scheme-full

    # Desktop
    libreoffice
    firefox

    # Wayland
    wl-clipboard
  ];
}
