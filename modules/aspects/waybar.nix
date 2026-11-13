{
  modules.waybar = {
    home-manager.sharedModules = [
      {
        programs.waybar = {
          enable = true;
          systemd.enable = true;
        };
      }
    ];
  };
}
