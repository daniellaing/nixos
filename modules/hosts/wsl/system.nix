{config, ...} @ outer: {
  hosts.wsl.modules.system = {
    config,
    lib,
    ...
  }: {
    system.stateVersion = "23.05"; # Do not change, ever
    imports = with outer.config.modules; [
      core
      base

      sops
      development
      home-manager
      zsh
    ];

    networking.networkmanager.enable = lib.mkForce false;

    sops.secrets.svn-passwd = {
      owner = config.users.users.daniel.name;
      group = config.users.users.daniel.group;
    };

    # Fixes that weird issue with nvim on wsl
    environment.sessionVariables.NVIM_NOTTYFAST = 1;
  };
}
