{config, ...}: {
  hosts.wsl.modules.system = {
    system.stateVersion = "23.05"; # Do not change, ever
    imports = with config.modules; [
      core
      base

      development
      home-manager
      zsh
    ];
  };
}
