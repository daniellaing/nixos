{
  inputs,
  config,
  lib,
  ...
}: let
  nix-index_enabled = builtins.any (cfg: cfg.programs.nix-index.enable) (builtins.attrValues config.home-manager.users);
in {
  imports = with inputs.nix-index-database; [
    nixosModules.nix-index
  ];

  config = lib.mkMerge [
    (lib.mkIf nix-index_enabled {
      programs = {
        nix-index.enable = true;
        nix-index-database.comma.enable = true;
      };
    })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.nix-index;
        in {
          options.cooked.nix-index = {
            enable = lib.mkEnableOption "nix-index configuration.";
          };

          imports = [
            inputs.nix-index-database.homeModules.nix-index
          ];

          config = lib.mkIf cfg.enable {
            programs.nix-index-database.comma.enable = true;
          };
        })
      ];
    }
  ];
}
