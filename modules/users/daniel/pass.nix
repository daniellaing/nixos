{config, ...}: {
  users.daniel.pass = {
    imports = with config.users.daniel; [base];

    home-manager.users.daniel = {config, ...}: {
      programs.password-store = {
        enable = true;
        settings = {
          PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
        };
      };
    };
  };
}
