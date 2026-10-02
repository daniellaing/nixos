{config, ...}: {
  hosts.wsl.users = {
    daniel = {
      imports = [config.users.daniel.core];
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
