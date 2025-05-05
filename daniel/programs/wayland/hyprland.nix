{
  config,
  pkgs,
  osConfig,
  ...
}: let
  col = config.colorScheme.palette;
  wallpaper = ../../wallpapers/summer-day.png;
in {
  imports = [
    ../../../modules/hyprpaper.nix
  ];

  programs.hyprpaper = {
    enable = true;
    inherit wallpaper;
  };

  home.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  wayland.windowManager.hyprland = {
    extraConfig = ''
      exec-once = hyprpaper
      exec = pkill waybar; waybar

      monitor = eDP-1,1920x1080,0x0,1

      general {
          layout = dwindle
          gaps_out = 15

          border_size = 2
          col.active_border = 0xff${col.base05}
          col.inactive_border = 0xff${col.base01}
          col.nogroup_border_active = 0xff${col.base05}
          col.nogroup_border = 0xff${col.base01}
      }

      decoration {
          rounding = 5

          # drop_shadow = yes
          # shadow_range = 0
          # shadow_render_power = 4
          # col.shadow = rgb(61694f)
          # col.shadow_inactive = rgb(2e3538)
          # shadow_scale = 1.0
          # shadow_offset = 0 10
      }

      animations {
        enabled = yes

        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        bezier = myBezier2, 0.65, 0, 0.35, 1
        bezier = linear, 0, 0, 1, 1

        bezier=slow,0,0.85,0.3,1
        bezier=overshot,0.13,0.99,0.29,1.1
        bezier=bounce,1,1.6,0.1,0.85
        bezier=slingshot,1,-1,0.15,1.25
        bezier=nice,0,6.9,0.5,-4.20

        animation = windows,1,5,bounce,popin
        animation = border,1,20,default
        animation = fade,1,3,overshot
        animation = workspaces,1,6,overshot,
        animation = windowsIn,1,5,slow,popin
        animation = windowsMove,1,5,default
      }

      cursor {
          inactive_timeout = 3
      }

      input {
          kb_layout = us,gb
          kb_variant = dvorak,
          kb_options = caps:swapescape,grp:ctrls_toggle
          numlock_by_default = true
          follow_mouse = 1
      }

      gestures {
          workspace_swipe = true
      }

      dwindle {
          force_split = 2   # Split to the right or bottom
      }

      master {
          new_on_top = true
      }

      misc {
          disable_hyprland_logo = true;
          enable_swallow = true;
          swallow_regex = ^(Alacritty|kitty)$
          swallow_exception_regex = ^ ?(wev|v|nvim) ?.*
      }

      # Keybinds
      $MOD = SUPER
      # bind = $MOD, B, #Toggle Status Bar
      # bind = $MOD, C, #Open Calendar

      bind = $MOD, E, exec, ${config.programs.terminal} neomutt
      # bind = $MOD SHIFT, E, #Open address book

      bind = $MOD, F, fullscreen, 0
      # bind = $MOD SHIFT, F, #Open ferdium

      # bind = $MOD, G, #Toggle gaps
      # bind = $MOD SHIFT, G, #Reset gaps

      # bind = $MOD, H, #Decrease master window size

      bind = $MOD, J, cyclenext,
      bind = $MOD SHIFT, J, swapwindow, u

      bind = $MOD, K, cyclenext, prev
      bind = $MOD SHIFT, K, swapwindow, d

      # bind = $MOD, L, #Increase master window size

      bind = $MOD, M, exec, ${config.XF86.music}
      # bind = $MOD SHIFT, M,  #Mute

      bind = $MOD, P, exec, ${config.XF86.audioPlay}

      bind = $MOD, Q, killactive,

      bind = $MOD, V, layoutmsg, focusmaster, master

      bind = $MOD, W, exec, $BROWSER
      # bind = $MOD, SHIFT, W, #Open network settings

      bind = $MOD, X, exec, ${config.XF86.explorer}
      # bind = $MOD, SHIFT X, #Decrease gaps

      # bind = $MOD, SHIFT, Z, #Increase gaps

      bind = $MOD, comma, exec, ${config.XF86.audioPrev}
      bind = $MOD, <, exec, ${config.XF86.audioRewind}

      bind = $MOD, period, exec, ${config.XF86.audioNext}

      bind = $MOD, Return, exec, ${config.programs.terminal}
      # bind = $MOD, Space, #Make current window master
      bind = $MOD SHIFT, Space, togglefloating,
      bind = $MOD, Backspace, exec, powermenu

      bind = $ALT, Space, exec, wofi -S drun -I

      # Workspaces
      bind = $MOD, 1, workspace, 1
      bind = $MOD, 2, workspace, 2
      bind = $MOD, 3, workspace, 3
      bind = $MOD, 4, workspace, 4
      bind = $MOD, 5, workspace, 5
      bind = $MOD, 6, workspace, 6
      bind = $MOD, 7, workspace, 7
      bind = $MOD, 8, workspace, 8
      bind = $MOD, 9, workspace, 9
      bind = $MOD SHIFT, 1, movetoworkspace, 1
      bind = $MOD SHIFT, 2, movetoworkspace, 2
      bind = $MOD SHIFT, 3, movetoworkspace, 3
      bind = $MOD SHIFT, 4, movetoworkspace, 4
      bind = $MOD SHIFT, 5, movetoworkspace, 5
      bind = $MOD SHIFT, 6, movetoworkspace, 6
      bind = $MOD SHIFT, 7, movetoworkspace, 7
      bind = $MOD SHIFT, 8, movetoworkspace, 8
      bind = $MOD SHIFT, 9, movetoworkspace, 9

      # Mouse binds
      bindm = $MOD, mouse:272, movewindow
      bindm = $MOD, mouse:273, resizewindow

      # XF86 (brace yourself)
      binde =, XF86AudioLowerVolume, exec, ${osConfig.XF86.audioLowerVolume}
      bind =, XF86AudioMute, exec, ${osConfig.XF86.audioMute}
      binde =, XF86AudioRaiseVolume, exec, ${osConfig.XF86.audioRaiseVolume}
      bind =, XF86AudioPlay, exec, ${config.XF86.audioPlay}
      bind =, XF86AudioStop, exec, ${config.XF86.audioStop}
      bind =, XF86AudioPrev, exec, ${config.XF86.audioPrev}
      bind =, XF86AudioNext, exec, ${config.XF86.audioNext}
      bind =, XF86Mail, exec, ${config.XF86.mail}
      bind =, XF86Calculator, exec, ${config.XF86.calculator}
      bind =, XF86WWW, exec, ${config.XF86.WWW}
      bind =, XF86AudioPause, exec, ${config.XF86.audioPause}
      bind =, XF86AudioRewind, exec, ${config.XF86.audioRewind}
      bind =, XF86Terminal, exec, ${config.XF86.terminal}
      bind =, XF86Music, exec, ${config.XF86.music}
    '';
  };

  systemd.user.services.polkit-kde-authentication-agent-1 = {
    Unit.Description = "KDE polkit authentication agent";
    Unit.Wants = ["graphical-session.target"];
    Unit.After = ["graphical-session.target"];
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
