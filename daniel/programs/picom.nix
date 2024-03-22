{
  config,
  pkgs,
  ...
}: {
  services.picom = {
    enable = false;
    extraArgs = ["--experimenal-backends"];
  };

  xdg.configFile."picom/picom.conf".text = ''
    #
    # GLX Settings
    #
    backend = "glx";
    glx-no-stencil = false;
    use-damage = true;
    vsync = true;

    #
    # Shadows
    #
    shadow = true;
    detect-rounded-corners = true;
    shadow-radius = 7;
    shadow-offset-x = -7;
    shadow-offset-y = -7;
    shadow-exclude = [
      "name = 'Notification'",
      "class_g = 'Conky'",
      "class_g ?= 'Notify-osd'",
      "class_g = 'Cairo-clock'",
      "_GTK_FRAME_EXTENTS@:c",
      "class_g = 'firefox' && argb"
    ];

    #
    # Transparency
    #
    active-opacity = 0.9;
    inactive-opacity = 0.9;
    inactive-dim = 0.1;
    frame-opacity = 0.7;

    #
    # Fading
    #
    fading = true;
    fade-in-step = 0.08;
    fade-out-step = 0.08;

    #
    # Blur
    #
    blur-method = "dual_kawase"
    blur-strength = 12
    blur-kern = "3x3box";
    blur-background-exclude = [
      "window_type = 'dock'",
      "window_type = 'desktop'",
      "class_g = 'slop'",
      "_GTK_FRAME_EXTENTS@:c"
    ];

    #
    # Rounded corners
    #
    corner-radius = 10
    rounded-corners-exclude = [
      "window_type = 'dock'",
      "window_type = 'desktop'",
      "class_g = 'dwm'"
    ];

    wintypes:
    {
      tooltip = { fade = true; shadow = true; opacity = 0.75; focus = true; full-shadow = false; };
      dock = { shadow = false; clip-shadow-above = true; }
      dnd = { shadow = false; }
    };
  '';
}
