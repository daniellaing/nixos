{
  users.daniel.r = {pkgs, ...}: let
    packages = with pkgs.rPackages; [
      tidyverse
      writexl

      # Development
      devtools
      roxygen2
      covr
    ];

    R = pkgs.rWrapper.override {inherit packages;};
    RStudio = pkgs.rstudioWrapper.override {inherit packages;};
  in {
    home-manager.users.daniel = {config, ...}: {
      home = {
        packages = [R RStudio];
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
  };
}
