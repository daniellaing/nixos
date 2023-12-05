{ config, pkgs, lib, ... }:
with config.colorScheme.colors;
let
  cfg = config.programs;
in
{
  options.programs = {
    terminal = lib.mkOption {
      # type = lib.types.path;
      description = "Your default terminal";
      example = "''${pkgs.kitty}/bin/kitty";
    };
  };

  config = {
    programs = {
      terminal = "${pkgs.kitty}/bin/kitty";

      kitty = {
        enable = true;
        extraConfig = ''
          box_drawing_scale 0.001, 1, 1.5, 2
          window_margin_width 10
          confirm_os_window_close 0
          foreground            #${base05}
          background            #${base00}
          selection_foreground  #${base05}
          selection_background  #${base02}
          cursor                #${base05}

          color0   #${base01}
          color8   #${base02}

          color1   #${base0E}
          color9   #${base0E}

          color2   #${base0D}
          color10  #${base0D}

          color3   #${base0A}
          color11  #${base0A}

          color4  #${base08}
          color12 #${base08}

          color5   #${base09}
          color13  #${base09}

          color6   #${base0B}
          color14  #${base0B}

          color7   #${base07}
          color15  #${base07}
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
}
