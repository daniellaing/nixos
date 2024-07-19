{
  config,
  pkgs,
  ...
}: let
  col = config.colorScheme.palette;
in {
  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix-Paper";
    };
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";

        width = "(300, 750)";
        origin = "top-right";
        offset = "24x24";

        progress_bar = true;
        progress_bar_height = 14;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;

        indicate_hidden = true;
        shrink = false;
        transparency = 1;
        separator_height = 6;
        separator_color = "#${col.base00}";
        padding = 16;
        horizontal_padding = 16;
        frame_width = 2;
        sort = true;
        idle_threshold = 0;

        font = "JetBrainsMono Nerd Font 14";
        line_height = 0;
        markup = "full";
        format = "<b>%a: %s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 120;
        word_wrap = true;
        ignore_newline = false;
        stack_duplicates = false;
        show_indicators = true;

        icon_position = "left";

        sticky_history = true;
        history_length = 100;

        dmenu = "${pkgs.wofi}/bin/wofi --show=dmenu -p dunst";
        browser = "$BROWSER";
        always_run_script = false;
        title = "Dunst";
        class = "Dunst";
        ignore_dbusclose = false;

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      urgency_low = {
        background = "#${col.base01}";
        foreground = "#${col.base05}";
        highlight = "#${col.base0F}";
        frame_color = "#${col.base0F}";
      };

      urgency_normal = {
        background = "#${col.base01}";
        foreground = "#${col.base05}";
        highlight = "#${col.base0C}";
        frame_color = "#${col.base0C}";
      };

      urgency_critical = {
        background = "#${col.base01}";
        foreground = "#${col.base05}";
        highlight = "#${col.base09}";
        frame_color = "#${col.base09}";
        timeout = 0;
      };

      music = {
        appname = "Music";
      };

      volume = {
        summary = "Volume";
      };

      battery = {
        appname = "Power Warning";
      };
    };
  };
}
