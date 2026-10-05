{config, ...}: {
  users.daniel.modules.syncthing = {
    imports = with config.modules; [syncthing];
    users.users.daniel.extraGroups = ["syncthing"];
    home-manager.users.daniel.services.syncthing = {
      enable = true;
    };
  };
}
