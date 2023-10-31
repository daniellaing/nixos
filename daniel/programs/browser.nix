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

  # xdg = {
  #   desktopEntries = {
  #     librewolf = {
  #       name = "Librewolf";
  #       genericName = "Web Browser";
  #       comment = "A fork of Firefox, focused on privacy, security and freedom";
  #       icon = "Librewolf";
  #       exec = "${pkgs.librewolf}/bin/librewolf %U";
  #       categories = [ "Network" "WebBrowser" ];
  #       mimeType = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
  #     };
  #     firefox = {
  #       name = "Firefox";
  #       genericName = "Web Browser";
  #       comment = "Mozilla Firefox, free web browser";
  #       icon = "Firefox";
  #       exec = "${pkgs.firefox}/bin/firefox %U";
  #       categories = [ "Network" "WebBrowser" ];
  #       mimeType = [ "x-scheme-handler/http" "x-scheme-handler/https" ];
  #     };
  #   };
  #   mimeApps.defaultApplications = {
  #     "x-scheme-handler/http" = "librewolf.desktop";
  #     "x-scheme-handler/https" = "librewolf.desktop";
  #   };
  # };

  home.sessionVariables.BROWSER = "${pkgs.librewolf}/bin/librewolf";
}
