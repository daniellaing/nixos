{ config, pkgs, ... }:
{
  programs = {

    kitty = {
      enable = true;
      extraConfig = ''
        box_drawing_scale 0.001, 1, 1.5, 2
        window_margin_width 10
        foreground            #323d43
        background            #fdf6e3
        selection_foreground  #e4e1cd
        selection_background  #d3dbc8
        url_color             #415c6d
        cursor                #7fbbb3

        # black
        color0   #4a555b
        color8   #525c62

        # red
        color1   #e68183
        color9   #e68183

        # green
        color2   #a7c080
        color10  #a7c080

        # yellow
        color3   #dbbc7f
        color11  #dbbc7f

        # blue
        color4  #7fbbb3
        color12 #7fbbb3

        # magenta
        color5   #d699b6
        color13  #d699b6

        # cyan
        color6   #83c092
        color14  #83c092

        # white
        color7   #f3efda
        color15  #f3efda
      '';
    };

    alacritty = {
      enable = true;
      settings = {
        colors = {
          primary = {
            background = "#282828";
            foreground = "#ebdbb2";
          };

          normal = {
            black = "#282828";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#a89984";
          };

          bright = {
            black = "#5e544a";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
            white = "#f8f2e3";
          };
        };

        window = {
          padding = {
            x = 10;
            y = 10;
          };
        };
      };
    };
  };

  home.sessionVariables.TERMINAL = "${pkgs.alacritty}/bin/alacritty";

}
