{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  hyprland_enabled = builtins.any (cfg: cfg.wayland.windowManager.hyprland.enable) (builtins.attrValues config.home-manager.users);
in
  lib.mkMerge [
    (lib.mkIf hyprland_enabled {
      # NixOS config
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      hardware.graphics = let
        ps = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in {
        package = ps.mesa;
        enable32Bit = true;
        package32 = ps.pkgsi686Linux.mesa;
      };
    })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.hyprland;
        in {
          # Common HM config
          options.cooked.hyprland = {
            enable = lib.mkEnableOption "user hyprland config";
          };

          config = lib.mkIf cfg.enable {
            wayland.windowManager.hyprland = {
              enable = true;
              package = null;
              portalPackage = null;

              systemd.variables = ["--all"];
            };
          };
        })
      ];
    }
  ]
