{config, ...}: {
  hosts.dellG5.modules.system = {
    system.stateVersion = "23.05"; # Do not change, ever
    imports = with config.modules; [
      core
      base

      sddm
      development
      home-manager
      zsh
    ];
  };
}
