{
  config,
  lib,
  pkgs,
  ...
}: let
  git_enabled = builtins.any (cfg: cfg.programs.git.enable) (builtins.attrValues config.home-manager.users);
in
  lib.mkMerge [
    (lib.mkIf git_enabled {
      programs.git.enable = true;
    })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.git;
        in {
          options.cooked.git = {
            enable = lib.mkEnableOption "user git config";
          };

          config = lib.mkIf cfg.enable {
            programs.git = {
              enable = true;
              settings = {
                alias = {
                  pa = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
                  cpa = "!f() { git commit \"$@\" && git pa; }; f";
                  lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date-order";
                };
                init = {
                  defaultBranch = "master";
                };
              };
            };
          };
        })
      ];
    }
  ]
