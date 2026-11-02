{config, ...} @ outer: {
  hosts.expat.users = {
    sysadmin = {config, ...}: {
      # Base off of Daniel's config
      imports = with outer.config.users.daniel; [
        # core
        # base
      ];

      users.users.sysadmin = {
        isNormalUser = true;
        description = "System administrator";
        extraGroups = [
          "wheel"
          "${config.services.forgejo.group}"
        ];
        initialPassword = "password";
      };
    };
  };
}
