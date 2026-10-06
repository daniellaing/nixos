{config, ...}: {
  # Base stuff for a graphical interface
  users.daniel.gui = {
    imports = with config.users.daniel; [
      dunst
      firefox
      mpv
      zathura
    ];
  };
}
