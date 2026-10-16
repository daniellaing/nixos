{config, ...}: {
  hosts.expat.users = {
    sysadmin = {
      # Base off of Daniel's config
      imports = with config.users.daniel; [
        # core
        # base
      ];

      users.users.sysadmin = {
        isNormalUser = true;
        description = "System administrator";
        extraGroups = [
          "wheel"
        ];
        initialPassword = "password";
      };
    };
  };
}
