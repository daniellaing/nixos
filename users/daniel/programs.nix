{
  lib,
  pkgs,
  ...
}: {
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
      userDirs.setSessionVariables = false;

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
