#!/bin/sh

set -ex
cfgdir="${1:-/dotfiles}"
cd "$cfgdir"

# Do the configuration
$SHELL

# Format
alejandra "$cfgdir" 1>/dev/null
git add .

if git diff --staged --quiet .; then
    echo "No changes detected, exiting"
    cd -
    exit 0
fi

nix flake check "$cfgdir"
nh os build "$cfgdir" || (
    notify-send -e -a "NixOS Rebuild", "Failure!"
    exit 1
)

git commit -a
nh os boot "$cfgdir"

cd -
notify-send -e -a "NixOS Rebuild" "Success!\nReboot for changes to take effect"
