{config, ...}: {
  hosts.expat.modules.forgejo = {
    imports = with config.modules; [forgejo-git];
  };
}
