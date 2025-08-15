{
  lib,
  config,
  ...
}: {
  imports = [
    ./dev.nix
    ./fonts.nix
    ./gnupg.nix
    ./network.nix
    ./nix.nix
    ./scripts.nix
    ./services
    ./sops.nix
    ./tmux.nix
    ./vm.nix
  ];

  options.cooked-preload = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["desktop" "server"]);
    default = null;
    description = "Preload options";
  };

  config.cooked =
    # Common config
    {
      dbus.enable = lib.mkDefault true;
      dev.enable = lib.mkDefault true;
      fonts.enable = lib.mkDefault true;
      gnupg.enable = lib.mkDefault true;
      locate.enable = lib.mkDefault true;
      network.enable = lib.mkDefault true;
      nix.enable = lib.mkDefault true;
      scripts = {
        enable = lib.mkDefault true;
        nix-helpers = lib.mkDefault true;
      };
      sops.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
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
      # scripts.menus.enable = lib.mkDefault true;
    });
}
