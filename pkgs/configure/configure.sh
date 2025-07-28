#!/bin/sh

set -ex
cfgdir="${1:-/dotfiles}"
cd "$cfgdir"

echo "TODO: Fix this script"

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

# Above has order fail
# so long as nix builds before git commits then the tree will always be dirty.
# 1. Make sure config builds correctly.
# 2. If not, fail. If yes, do commit.
# 3. Switch to the new config.
# 4. Get generation number
# 5. Ammend commit message to append generation.

rm /tmp/rebuild_commit_msg
cd -
notify-send -e -a "NixOS Rebuild" "Success!"
