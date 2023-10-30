{ config, pkgs, ... }:
let
  h = config.home.homeDirectory;
in
{
  xdg = {
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
      music = h + "/archive/media/audio/music";
      pictures = h + "/archive/media/pictures";
      publicShare = h + "/archive/public";
      templates = h + "/archive/templates";
      videos = h + "/archive/media/video";
    };
    desktopEntries = { };
  };
}
