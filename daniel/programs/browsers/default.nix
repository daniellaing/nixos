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
          search = {
            force = true;
            default = "SearxNG";
            engines = {
              "SearxNG" = {
                urls = [{
                  template = "https://freesearch.club/search";
                  params = [
                    { name = "q"; value = "{searchTerms}"; }
                  ];
                }];
              };
              "Nix Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    { name = "type"; value = "packages"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              "Nix Options" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    { name = "type"; value = "packages"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };
              "Home Manager Options" = {
                urls = [{
                  template = "https://mipmip.github.io/home-manager-option-search";
                  params = [
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@hm" ];
              };
            };
          };
        };
      };
    })
    browsers);
}
