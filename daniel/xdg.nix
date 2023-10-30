{ config, pkgs, ... }:

{
  xdg = {
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}";
      documents = "${config.home.homeDirectory}/archive";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/archive/media/audio/music";
      pictures = "${config.home.homeDirectory}/archive/media/pictures";
      publicShare = "${config.home.homeDirectory}/archive/public";
      templates = "${config.home.homeDirectory}/archive/templates";
      videos = "${config.home.homeDirectory}/archive/media/video";
    };
    desktopEntries = { };
  };
}
