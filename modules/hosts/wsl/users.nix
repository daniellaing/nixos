{config, ...}: {
  hosts.wsl.users = {
    daniel = {
      imports = with config.users.daniel; [
        core
        base

        music

        zsh
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

    vmtest = {
      users.users.vmtest = {
        isNormalUser = true;
        initialPassword = "password";
        description = "VM test user";
        extraGroups = [
          "wheel"
        ];
      };
    };
  };
}
