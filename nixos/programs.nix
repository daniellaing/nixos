{pkgs, ...}: let
  pypkgs = ps:
    with ps; [
      numpy
      requests
      pandas
      pip
    ];

  rebuild-script =
    pkgs.writeShellApplication
    {
      name = "configure";
      runtimeInputs = with pkgs; [git bat ripgrep libnotify];
      text = ''
        set -ex
        pushd /dotfiles
        $EDITOR .
        if git diff --quiet .; then
            echo "No changes detected, exiting"
            popd
            exit 0
        fi
        nix fmt &> /dev/null
        git diff -U0 .
        # shellcheck disable=SC2024
        sudo nixos-rebuild switch --flake /dotfiles &> nixos-rebuild.log || (notify-send -e -a "NixOS Rebuild" "Failure!"; bat nixos-rebuild.log | rg error && exit 1)
        msg=$(nixos-rebuild list-generations --flake /dotfiles | rg current)
        git commit -am "$msg"
        popd
        notify-send -e -a "NixOS Rebuild" "Success!"
      '';
    };
in {
  environment.systemPackages = with pkgs; [
    rebuild-script
    # Utility
    git
    gcc
    unzip
    wget
    ripgrep
    gnumake
    pinentry-curses
    gnupg
    (uutils-coreutils.override {prefix = "";}) # Coreutils rewrite in Rust btw

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
