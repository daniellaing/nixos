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

    # Development
    (python3.withPackages pypkgs)
    cargo
    texlive.combined.scheme-full

    # Desktop
    libreoffice
    firefox
  ];

  nixpkgs.config.allowAliases = false;
}
