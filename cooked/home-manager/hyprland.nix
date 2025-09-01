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
      # Hyprland cache
      nix.settings = {
        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };

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

              systemd = {
                variables = ["--all"];
              };
            };

            systemd.user.services.hyprpolkitagent = {
              Unit = {
                Description = "Hyprland polkit authentication agent";
                PartOf = [config.wayland.systemd.target];
                After = [config.wayland.systemd.target];
              };
              Install.WantedBy = [config.wayland.systemd.target];
              Service = {
                Type = "simple";
                ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
          };
        })
      ];
    }
  ]
