{
  config,
  pkgs,
  ...
}: let
  mpc = "${pkgs.mpc-cli}/bin/mpc";
in {
  imports = [../../modules/XF86.nix];

  XF86 = {
    audioPlay = "${mpc} toggle";
    audioPause = "${mpc} pause";
    audioStop = "${mpc} pause";
    audioPrev = "${mpc} prev";
    audioNext = "${mpc} next";
    audioRewind = "${mpc} seek 0";
    audioRepeat = "${mpc} repeat";
    audioRandomPlay = "${mpc} random";
  };

  services = {
    mpd = {
      enable = true;
      musicDirectory = "${config.xdg.userDirs.music}";
      network.startWhenNeeded = true;
      extraConfig = ''
        restore_paused "yes"
        auto_update "yes"

        audio_output {
            type "pipewire"
            name "PipeWire Sound Server"
        }
        audio_output {
            type "fifo"
            name "Visualizer feed"
            path "/tmp/mpd.fifo"
            format "44100:16:2"
        }
      '';
    };
  };

  programs = {
    ncmpcpp = {
      enable = true;
      package = pkgs.ncmpcpp.override {visualizerSupport = true;};
      bindings = [
        {
          key = "j";
          command = "scroll_down";
        }
        {
          key = "k";
          command = "scroll_up";
        }
        {
          key = "ctrl-u";
          command = "page_up";
        }
        {
          key = "ctrl-d";
          command = "page_down";
        }
        {
          key = "u";
          command = "page_up";
        }
        {
          key = "d";
          command = "page_down";
        }
        {
          key = "h";
          command = "previous_column";
        }
        {
          key = "l";
          command = "next_column";
        }
        {
          key = ".";
          command = "show_lyrics";
        }
        {
          key = "n";
          command = "next_found_item";
        }
        {
          key = "N";
          command = "previous_found_item";
        }
        {
          key = "J";
          command = "move_sort_order_down";
        }
        {
          key = "K";
          command = "move_sort_order_up";
        }
        {
          key = "h";
          command = "jump_to_parent_directory";
        }
        {
          key = "l";
          command = "enter_directory";
        }
        {
          key = "l";
          command = "run_action";
        }
        {
          key = "l";
          command = "play_item";
        }
        {
          key = "g";
          command = "move_home";
        }
        {
          key = "G";
          command = "move_end";
        }
        {
          key = "v";
          command = "show_visualizer";
        }
        {
          key = "s";
          command = "show_search_engine";
        }
        {
          key = "s";
          command = "reset_search_engine";
        }
        {
          key = "x";
          command = "delete_playlist_items";
        }
      ];
      settings = {
        alternative_header_first_line_format = "$b$1$aqqu$/a$9 {%t}|{%f} $1$atqq$/a$9$/b";
        alternative_header_second_line_format = "{{$4$b%a$/b$9}{ - $7%b$9}{ ($4%y$9)}}|{%D}";
        browser_display_mode = "columns";
        current_item_inactive_column_prefix = "$(magenta)$r";
        current_item_inactive_column_suffix = "$/r$(end)";
        current_item_prefix = "$(cyan)$r$b";
        current_item_suffix = "$/r$(end)$/b";
        display_volume_level = "no";
        empty_tag_color = "magenta";
        external_editor = "$EDITOR";
        ignore_leading_the = "yes";
        lyrics_directory = "${config.xdg.dataHome}/lyrics";
        main_window_color = "white";
        media_library_albums_split_by_date = "no";
        media_library_primary_tag = "album_artist";
        message_delay_time = "1";
        playlist_display_mode = "columns";
        progressbar_color = "black:b";
        progressbar_elapsed_color = "blue:b";
        song_library_format = "{%n - }{%t}|{%f}";
        song_list_format = "{$4%a - }{%t}|{$8%f$9}$R{$3(%l)$9}";
        song_status_format = ''$b{{$8"%t "}} $3by {$4%a{ $3in $7%b{ (%y)}} $3}|{$8%f}'';
        startup_screen = "media_library";
        statusbar_color = "red";
        statusbar_time_color = "cyan:b";
        use_console_editor = "yes";
        visualizer_spectrum_smooth_look = "yes";
        visualizer_type = "spectrum";
      };
    };

    beets = {
      enable = true;
      mpdIntegration = {
        enableStats = true;
        enableUpdate = true;
      };
      settings = {
        directory = "${config.xdg.userDirs.music}";
        library = "${config.xdg.dataHome}/beets/musiclibrary.db";
        import = {
          move = true;
        };
      };
    };
  };
}
