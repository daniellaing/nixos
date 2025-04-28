#!/bin/sh

set -ex
cfgdir="${1:-/dotfiles}"
cd "$cfgdir"
nix flake update --commit-lock-file

# nixos-rebuild switch --flake "$cfgdir"
# shellcheck disable=SC2024
nh os boot "$cfgdir" || (notify-send -e -a "NixOS Update", "Failure!"; exit 1)

msg=$(nixos-rebuild list-generations --flake "$cfgdir" | rg current)
old_msg=$(git log --format=%B -n1)
git commit --amend -m "$old_msg" -m "$msg"
cd -
notify-send -e -a "NixOS Update" "Success!\n System will restart in 2 minutes"
shutdown -r 2
