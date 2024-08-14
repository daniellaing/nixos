{
  lib,
  config,
  ...
}: let
  cfg = config;
in {
  imports = [
    ./fonts.nix
    ./network.nix
    ./nix-index.nix
    ./scripts.nix
    ./services
    ./vm.nix
  ];

  options = {
    cooked-preload = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["desktop" "server"]);
      default = null;
      description = "Preload options";
    };
  };

  config = {
    cooked =
      # Common config
      {
        fonts.enable = lib.mkDefault true;
        network.enable = lib.mkDefault true;
        scripts = {
          enable = lib.mkDefault true;
          nix-helpers = lib.mkDefault true;
        };
        locate.enable = lib.mkDefault true;
      }
      //
      # Server config
      (lib.optionalAttrs (cfg.cooked-preload == "server") {
        })
      //
      # Desktop config
      (lib.optionalAttrs (cfg.cooked-preload == "desktop") {
        display-manager.enable = lib.mkDefault true;
        printing.enable = lib.mkDefault true;
        sound.enable = lib.mkDefault true;
      });
  };
}
