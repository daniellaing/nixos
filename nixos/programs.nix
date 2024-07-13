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
      runtimeInputs = with pkgs; [git bat ripgrep libnotify nh alejandra];
      text = ''
        set -ex
        cfgdir="''${1:-/dotfiles}"
        pushd "$cfgdir"
        $EDITOR .
        git add .
        if git diff --staged --quiet .; then
            echo "No changes detected, exiting"
            popd
            exit 0
        fi

        # Format
        alejandra "$cfgdir" &> /dev/null

        # nixos-rebuild switch --flake "$cfgdir"
        # shellcheck disable=SC2024
        nh os switch "$cfgdir" || (notify-send -e -a "NixOS Rebuild", "Failure!"; exit 1)

        msg=$(nixos-rebuild list-generations --flake "$cfgdir" | rg current)
        git commit -am "$msg"
        popd
        notify-send -e -a "NixOS Rebuild" "Success!"
      '';
    };

  update-script =
    pkgs.writeShellApplication
    {
      name = "update-system";
      runtimeInputs = with pkgs; [git libnotify nh];
      text = ''
        set -ex
        cfgdir="''${1:-/dotfiles}"
        pushd "$cfgdir"
        nix flake update --commit-lock-file

        # nixos-rebuild switch --flake "$cfgdir"
        # shellcheck disable=SC2024
        nh os boot "$cfgdir" || (notify-send -e -a "NixOS Update", "Failure!"; exit 1)

        msg=$(nixos-rebuild list-generations --flake "$cfgdir" | rg current)
        old_msg=$(git log --format=%B -n1)
        git commit --amend -m "$old_msg" -m "$msg"
        popd
        notify-send -e -a "NixOS Update" "Success!\n System will restart in 2 minutes"
        shutdown -r 2
      '';
    };
in {
  environment.systemPackages = with pkgs; [
    rebuild-script
    update-script
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
