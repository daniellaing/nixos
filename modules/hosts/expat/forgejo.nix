{config, ...}: {
  hosts.expat.modules.forgejo = {
    imports = with config.modules; [forgejo-git];

    services.forgejo = {
      settings.server = {
        # DOMAIN = "git.localhost";
      };
    };
  };
}
