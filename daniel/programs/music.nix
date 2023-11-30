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
    };
  };
}
