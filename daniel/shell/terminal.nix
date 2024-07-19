{
  config,
  pkgs,
  lib,
  ...
}: let
  col = config.colorScheme.palette;
in {
  config = {
    programs = {
      terminal = "${pkgs.kitty}/bin/kitty";

      kitty = {
        enable = true;
        extraConfig = ''
          box_drawing_scale 0.001, 1, 1.5, 2
          window_margin_width 10
          confirm_os_window_close 0
          foreground            #${col.base05}
          background            #${col.base00}
          selection_foreground  #${col.base05}
          selection_background  #${col.base02}
          cursor                #${col.base05}

          color0   #${col.base01}
          color8   #${col.base02}

          color1   #${col.base0E}
          color9   #${col.base0E}

          color2   #${col.base0D}
          color10  #${col.base0D}

          color3   #${col.base0A}
          color11  #${col.base0A}

          color4  #${col.base08}
          color12 #${col.base08}

          color5   #${col.base09}
          color13  #${col.base09}

          color6   #${col.base0B}
          color14  #${col.base0B}

          color7   #${col.base07}
          color15  #${col.base07}
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

    home.sessionVariables.TERMINAL = "${config.programs.terminal}";
    home.sessionVariables.TERM = "${config.programs.terminal}";
  };

  options.programs = {
    terminal = lib.mkOption {
      # type = lib.types.path;
      description = "Your default terminal";
      example = "''${pkgs.kitty}/bin/kitty";
    };
  };
}
