{config, ...} @ outer: {
  users.daniel.waybar = {
    imports = with outer.config.modules; [waybar];
  };
}
