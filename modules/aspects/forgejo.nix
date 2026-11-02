{config, ...} @ outer: {
  modules.forgejo = {
    config,
    host,
    lib,
    ...
  }: let
    srv = config.services.forgejo.settings.server;
  in {
    imports = with outer.config.modules; [nginx];

    options.forgejo.custom = {
      ensureUsers = lib.mkOption {
        type = lib.types.listOf lib.types.submodule {
          options = {
            user = lib.mkOption {
              type = lib.types.str;
              description = "The username";
            };
            passwd = lib.mkOption {
              type = lib.types.str;
              description = "The user's password";
            };
            admin = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether the user should be an admin";
            };
          };
        };
        default = [];
        description = "Users to ensure always exist";
      };
    };

    config = {
      services.forgejo = {
        enable = true;
        settings = {
          server = {
            DOMAIN = "git.${host.domain}";
            ROOT_URL = "http://${srv.DOMAIN}";
            SSH_PORT = lib.mkIf config.services.openssh.enable (lib.lists.head config.services.openssh.ports);
          };
        };

        database = {
          user = config.services.forgejo.user;
        };
      };

      # TODO: Create ensured users

      services.nginx = {
        virtualHosts."${srv.DOMAIN}" = {
          # forceSSL = true;
          # enableACME = true;
          locations."/".proxyPass = "http://${host.domain}:${toString srv.HTTP_PORT}";
        };
      };

      # security.acme.acceptTerms = true;
    };
  };

  modules.forgejo-git = {config, ...}: let
    cfg = config.services.forgejo;
  in {
    imports = with outer.config.modules; [forgejo];

    services.forgejo = {
      user = "git";
      group = "git";
    };

    users.users.git = {
      home = cfg.stateDir;
      useDefaultShell = true;
      group = cfg.group;
      isSystemUser = true;
    };

    users.groups.git = {};
  };
}
