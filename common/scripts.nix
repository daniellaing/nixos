{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.scripts;
in {
  options.scripts = {
    enable = lib.mkEnableOption ''
      Enable scripts
    '';
    nix-helpers = lib.mkEnableOption ''
      Enable nix helper scripts
    '';
  };

  config = let
    rebuild-script =
      pkgs.writeShellApplication
      {
        name = "configure";
        runtimeInputs = builtins.attrValues {inherit (pkgs) git bat ripgrep libnotify nh alejandra;};
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
          alejandra "$cfgdir" 1> /dev/null

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
        runtimeInputs = builtins.attrValues {inherit (pkgs) git libnotify nh;};
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
  in
    lib.mkIf cfg.enable {
      environment.systemPackages = lib.lists.optionals cfg.nix-helpers [
        rebuild-script
        update-script
      ];
    };
}
