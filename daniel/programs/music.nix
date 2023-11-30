{ config, pkgs, ... }:

{
  services = {
    mpd = {
      enable = true;
      musicDirectory = "${config.xdg.userDirs.music}";
    };
  };

  programs = {
    ncmpcpp = {
      enable = true;
    };

    beets = {
      enable = true;
      mpdIntegration = {
        enableStats = true;
        enableUpdate = true;
      };
      settings = {
        directory = "${config.xdg.userDirs.music}";
        library = "${config.xdg.dataHome}/beets/musiclibrary.db";
        import = {
          move = "yes";
        };
      };
    };
  };
}
