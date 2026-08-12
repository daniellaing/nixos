{
  lib,
  pkgs,
  config,
  ...
}: let
  h = config.home-manager.users.daniel.home.homeDirectory;
in {
  home-manager.users.daniel = {
    programs = {
      # ---   Git   ---
      git = {
        settings = {
          user.email = lib.mkDefault "daniel@daniellaing.com";
          user.name = "Daniel Laing";
        };
        signing = {
          key = lib.mkDefault "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
          signByDefault = true;
        };
      };

      # ---   MPV   ---
      mpv = {
        enable = true;
        scripts = builtins.attrValues {
          inherit
            (pkgs.mpvScripts)
            sponsorblock
            ;
        };
      };
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

      desktopEntries = {
        mpv = {
          name = "mpv";
          genericName = "Video Player";
          comment = "A free, open-source, cross-platform video player";
          exec = "mpv %U";
          icon = "mpv";
          type = "Application";
          categories = ["Player" "Video"];
          mimeType = ["video/*"];
        };
      };
      mimeApps.defaultApplications = {
        "video/*" = "mpv.desktop";
      };
    };
  };
}
