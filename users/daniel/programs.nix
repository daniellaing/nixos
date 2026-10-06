{
  lib,
  pkgs,
  config,
  ...
}: let
  # h = config.home-manager.users.daniel.home.homeDirectory;
  h = config.home.homeDirectory;
in {
  # home-manager.users.daniel = {
  programs = {
    # ---   Home manager   ---
    home-manager.enable = true; # Let home manager manage itself
  };

  xdg = {
    enable = true;

    userDirs.setSessionVariables = false;
    cacheHome = h + "/.cache";
    configHome = h + "/.config";
    dataHome = h + "/.local/share";
    stateHome = h + "/.local/state";
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = h + "";
      documents = h + "/archive";
      download = h + "/downloads";
      music = h + "/archive/media/music";
      pictures = h + "/archive/media/pictures";
      publicShare = h + "/archive/public";
      templates = h + "/archive/templates";
      videos = h + "/archive/media/video";
    };
  };
  # };
}
