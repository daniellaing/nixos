{ config, pkgs, ... }:

{
  programs = {
    firefox = {
      enable = true;
    };
    librewolf = {
      enable = true;
    };
  };

  xdg = {
    desktopEntries = {
      librewolf = {
        name = "Librewolf";
        genericName = "Web Browser";
        comment = "Surf the web";
        exec = "${pkgs.librewolf}/bin/librewolf %U";
        categories = [ "Network" "Browser" "GUI" ];
        mimeType = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
      };
      firefox = {
        name = "Firefox";
        genericName = "Web Browser";
        comment = "Surf the web";
        exec = "${pkgs.firefox}/bin/firefox %U";
        categories = [ "Network" "Browser" "GUI" ];
        mimeType = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
      };
    };
    mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
    };
  };

  home.sessionVariables.BROWSER = "${pkgs.librewolf}/bin/librewolf";
}
