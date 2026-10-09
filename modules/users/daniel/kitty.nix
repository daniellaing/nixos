{config, ...} @ outer: {
  users.daniel.kitty = {
    config,
    lib,
    ...
  }: {
    imports = with outer.config.modules; [xf86];

    home-manager.users.daniel = {
      home.sessionVariables = {
        TERMINAL = "xterm-256color";
        TERM = "xterm-256color";
      };
      xf86.terminal = lib.getExe config.programs.kitty.package;

      kitty = {
        enable = true;
        extraConfig = ''
          box_drawing_scale 0.001, 1, 1.5, 2
          window_margin_width 10
          confirm_os_window_close 0
          foreground            #ddc7a1
          background            #292828
          selection_foreground  #ddc7a1
          selection_background  #504945
          cursor                #ddc7a1

          color0   #32302f
          color8   #504945

          color1   #d2869b
          color9   #d2869b

          color2   #7daea3
          color10  #7daea3

          color3   #d8a657
          color11  #d8a657

          color4  #ea6962
          color12 #ea6962

          color5   #e78a4e
          color13  #e78a4e

          color6   #a9b665
          color14  #a9b665

          color7   #fbf1c7
          color15  #fbf1c7
        '';
      };
    };
  };
}
