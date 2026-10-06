{
  config,
  inputs,
  ...
} @ outer: {
  users.daniel.firefox = {
    lib,
    pkgs,
    ...
  }: let
    firefoxBin = lib.getBin pkgs.firefox;
  in {
    imports = with config.modules; [
      xf86
    ];

    # NUR overlay
    nixpkgs.overlays = [inputs.nur.overlays.default];

    home-manager.users.daniel = {config, ...}: {
      imports = with outer.config.users.daniel; [bookmarks];
      home.sessionVariables.BROWSER = firefoxBin;
      xf86.WWW = firefoxBin;

      programs.firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        profiles.daniel = {
          bookmarks = {
            force = true;
            settings = config.bookmarks;
          };
          settings = {
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.startup.couldRestoreSession.count" = 2;
          };
          extensions.packages = builtins.attrValues {
            inherit
              (pkgs.nur.repos.rycee.firefox-addons)
              keepassxc-browser
              ublock-origin
              sponsorblock
              ;
          };
          search = {
            force = true;
            default = "ddg"; # DuckDuckGo is built-in
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@no"];
              };
              "Home Manager Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "source";
                        value = "home_manager";
                      }
                      {
                        name = "type";
                        value = "options";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@hm"];
              };
              "Dictionary" = {
                urls = [
                  {
                    template = "https://www.dictionary.com/browse/{searchTerms}";
                  }
                ];
                definedAliases = ["@d"];
              };
              "Thesaurus" = {
                urls = [
                  {
                    template = "https://www.thesaurus.com/browse/{searchTerms}";
                  }
                ];
                definedAliases = ["@t"];
              };
            };
          };
        };
      };
    };
  };
}
