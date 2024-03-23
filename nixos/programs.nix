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
        cfgdir="''${1:-/dotfiles}"
        pushd "$cfgdir"
        $EDITOR .
        if git diff --quiet .; then
            echo "No changes detected, exiting"
            popd
            exit 0
        fi
        nix fmt &> /dev/null
        # shellcheck disable=SC2024
        sudo nixos-rebuild switch --flake "$cfgdir" || (notify-send -e -a "NixOS Rebuild" "Failure!"; exit 1)
        msg=$(nixos-rebuild list-generations --flake "$cfgdir" | rg current)
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
