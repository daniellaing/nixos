{
  lib,
  pkgs,
  ...
}: let
  R_pkgs = builtins.attrValues {
    inherit
      (pkgs.rPackages)
      tidyverse
      writexl
      # Development
      
      devtools
      roxygen2
      covr
      ;
  };

  R = pkgs.rWrapper.override {packages = R_pkgs;};

  RStudio = pkgs.rstudioWrapper.override {packages = R_pkgs;};
in
  lib.mkMerge [
    {
      environment.systemPackages = [
        R
        RStudio
      ];
    }

    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.R;
        in {
          options.cooked.R = {
            enable = lib.mkEnableOption "user R config";
          };

          config = lib.mkIf cfg.enable {
            home = {
              file.".Renviron".text = ''R_LIBS_USER = "${config.xdg.dataHome}/R/x86_64-pc-linux-gnu-library"'';
              sessionVariables = {
                R_HOME_USER = "${config.xdg.configHome}/R";
                R_PROFILE_USER = "${config.xdg.configHome}/R/profile";
                R_PROFILE = "${config.xdg.configHome}/R/profile";
                R_HISTFILE = "${config.xdg.configHome}/R/history";
              };
            };
            xdg.configFile."R/profile".text = ''
              if (interactive()) {
                suppressMessages(require(devtools))
              }
            '';
          };
        })
      ];
    }
  ]
