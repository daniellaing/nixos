{config, ...}: {
  hosts.wsl.users = {
    daniel = {
      imports = with config.users.daniel; [
        core
        base

        development
        zsh
      ];
      users.users.daniel = {
        isNormalUser = true;
        description = "Daniel Laing";
        extraGroups = [
          "wheel"
        ];
      };
    };
  };
}
