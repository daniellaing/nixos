{
  lib,
  config,
  ...
}: let
  tmux_enabled = builtins.any (cfg: cfg.cooked.tmux.enable) (builtins.attrValues config.home-manager.users);
in
  lib.mkMerge [
    (lib.mkIf tmux_enabled {
      programs.tmux = {
        enable = true;
        escapeTime = lib.mkDefault 10;
        keyMode = lib.mkDefault "vi";
        clock24 = lib.mkDefault true;
      };
    })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.tmux;
        in {
          options.cooked.tmux = {
            enable = lib.mkEnableOption "tmux";
            conf = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Configuration to put in `tmux.conf`";
            };
          };

          config = lib.mkIf cfg.enable {
            # programs.tmux.enable = true;
            xdg.configFile."tmux/tmux.conf".text = cfg.conf;
          };
        })
      ];
    }
  ]
