{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      R
      rstudio
    ];

    sessionVariables = {
      R_HOME_USER = "${config.xdg.configHome}/R";
      R_PROFILE_USER = "${config.xdg.configHome}/R/profile";
      R_HISTFILE = "${config.xdg.configHome}/R/history";
    };
  };
}
