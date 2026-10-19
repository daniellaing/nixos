{config, ...}: {
  users.daniel.thunderbird = {
    imports = with config.users.daniel; [emailAccounts];

    home-manager.users.daniel = {
      programs.thunderbird = {
        enable = true;
        profiles.default.isDefault = true;
      };
    };
  };
}
