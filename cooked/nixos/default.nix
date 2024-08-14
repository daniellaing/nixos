{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    ./fonts.nix
    ./network.nix
    ./scripts.nix
    ./services
    ./vm.nix

    inputs.nix-index-database.nixosModules.nix-index
  ];

  options.cooked-preload = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["desktop" "server"]);
    default = null;
    description = "Preload options";
  };

  config.cooked =
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
    (lib.optionalAttrs (config.cooked-preload == "server") {
      })
    //
    # Desktop config
    (lib.optionalAttrs (config.cooked-preload == "desktop") {
      display-manager.enable = lib.mkDefault true;
      printing.enable = lib.mkDefault true;
      sound.enable = lib.mkDefault true;
    });
}
