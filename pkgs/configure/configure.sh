#!/bin/sh

set -ex
cfgdir="${1:-/dotfiles}"
cd "$cfgdir"

# Do the configuration
$SHELL

git add .

# Format
alejandra "$cfgdir" 1> /dev/null

if git diff --staged --quiet .; then
    echo "No changes detected, exiting"
    cd -
    exit 0
fi


# nixos-rebuild switch --flake "$cfgdir"
# shellcheck disable=SC2024
nh os switch "$cfgdir" || (notify-send -e -a "NixOS Rebuild", "Failure!"; exit 1)

msg=$(nixos-rebuild list-generations --flake "$cfgdir" | rg current)
git commit -am "$msg"
cd -
notify-send -e -a "NixOS Rebuild" "Success!"
