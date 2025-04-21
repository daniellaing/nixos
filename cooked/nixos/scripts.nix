{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.scripts;
in {
  options.cooked.scripts = {
    enable = lib.mkEnableOption "scripts";
    nix-helpers = lib.mkEnableOption "nix helper scrips";
    menus.enable = lib.mkEnableOption "menus";
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

    powermenu = pkgs.writeShellApplication {
      name = "powermenu";
      runtimeInputs = builtins.attrValues {
        inherit
          (pkgs)
          wofi
          waylock
          hyprland
          ;
      };
      text = ''
        options=(" Lock" " Sleep" "󰍃 Logout" " Reboot" "󰐥 Shutdown")
        prompt="$(uptime | sed -r 's/.*up ([^,]*),.*/\1/')"
        sel="$(printf '%s\n' "''${options[@]}" | wofi --show=dmenu -p "$prompt")"

        case $sel in
            *Shutdown*)
                systemctl poweroff
            ;;

            *Reboot*)
                systemctl reboot
            ;;

            *Sleep*)
                systemctl suspend
            ;;

            *Lock*)
                waylock
            ;;

            *Logout*)
                hyprctl dispatch exit
            ;;

            *)
                echo Unknown option
            ;;
        esac
      '';
    };
  in
    lib.mkIf cfg.enable {
      environment.systemPackages =
        lib.lists.optionals cfg.nix-helpers [
          rebuild-script
          update-script
        ]
        ++ lib.mkIf cfg.menus.enable [
          powermenu
        ];
    };
}
