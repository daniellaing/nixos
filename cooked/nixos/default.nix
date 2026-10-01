{
  lib,
  config,
  pkgs,
  type,
  ...
}: let
  cfg = config.cooked;
in {
  imports = [
    ./gnupg.nix
    ./scripts.nix
    ./services
    ./sops.nix
    ./vm.nix
  ];

  config = lib.mkMerge [
    # Common config
    {
      cooked = {
        gnupg.enable = lib.mkDefault true;
        locate.enable = lib.mkDefault true;
        scripts = {
          enable = lib.mkDefault true;
          nix-helpers = lib.mkDefault true;
        };
        sops.enable = lib.mkDefault true;
      };

      environment.systemPackages = with pkgs; [
        ripgrep
        unzip
        wget
      ];
    }

    # Server configuration
    (lib.mkIf cfg.preload.server {})

    # Desktop configuration
    (lib.mkIf cfg.preload.desktop {
      cooked = {
        display-manager.enable = lib.mkDefault true;
        printing.enable = lib.mkDefault true;
        # scripts.menus.enable = lib.mkDefault true;
      };
    })
  ];
}
