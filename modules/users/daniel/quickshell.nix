{
  users.daniel.quickshell = {
    home-manager.users.daniel = {
      programs.quickshell = {
        enable = true;
        systemd.enable = true;
      };
    };
  };
}
