{config, ...}: {
  hosts.expat.modules.forgejo = {
    imports = with config.modules; [forgejo];

    services.forgejo = {
      settings.server = {
        # DOMAIN = "git.localhost";
      };
    };
  };
}
