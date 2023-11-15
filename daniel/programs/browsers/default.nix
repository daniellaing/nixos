{ config, pkgs, ... }@inputs:
let
  browsers = [ "firefox" ];
in
{
  # Set default browser
  home.sessionVariables.BROWSER = "${pkgs.firefox}/bin/firefox";

  programs = builtins.listToAttrs (map
    (b: {
      name = b;
      value = {
        enable = true;
        profiles.daniel = {
          bookmarks = import ./bookmarks.nix (inputs);
          settings = {
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.startup.couldRestoreSession.count" = 2;
          };
        };
      };
    })
    browsers);
}
