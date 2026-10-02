{config, ...} @ outer: {
  hosts.wsl.modules.system = {config, ...}: {
    system.stateVersion = "23.05"; # Do not change, ever
    imports = with outer.config.modules; [
      core
      base

      sops
      development
      home-manager
      zsh
    ];

    sops.secrets.svn-passwd = {
      owner = config.users.users.daniel.name;
      group = config.users.users.daniel.group;
    };
  };
}
