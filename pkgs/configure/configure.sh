#!/bin/sh

set -ex
cfgdir="${1:-/dotfiles}"
cd "$cfgdir"

# Do the configuration
$SHELL

git add .

# Format
alejandra "$cfgdir" 1>/dev/null

if git diff --staged --quiet .; then
    echo "No changes detected, exiting"
    cd -
    exit 0
fi

# nixos-rebuild switch --flake "$cfgdir"
# shellcheck disable=SC2024
nh os switch "$cfgdir" || (
    notify-send -e -a "NixOS Rebuild", "Failure!"
    exit 1
)

nixos-rebuild list-generations --flake "$cfgdir" | rg 'True' >/tmp/rebuild_commit_msg
git commit -a -t /tmp/rebuild_commit_msg
rm /tmp/rebuild_commit_msg
cd -
notify-send -e -a "NixOS Rebuild" "Success!"
