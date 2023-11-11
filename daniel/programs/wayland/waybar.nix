{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        "margin-top" = 0;
        "margin-left" = 120;
        "margin-bottom" = 0;
        "margin-right" = 120;
        "height" = 60;
        "layer" = "top";
        "position" = "top";
        "spacing" = 15;
        "modules-left" = [ "custom/launcher" "clock" "clock#date" ];
        "modules-cetrer" = [ "hyprland/workspaces" ];
        "modules-right" = [ "pulseaudio" "network" "battery" "custom/powermenu" ];

        "hyprland/workspaces" = {
          "on-click" = "activate";
          "on-scroll-up" = "hyprctl dispatch workspace +1";
          "on-scroll-down" = "hyprctl dispatch workspace -1";
          "persistent_workspaces" = {
            "1" = [ "eDP-1" ];
          };
        };

        "custom/launcher" = {
          "interval" = "once";
          "format" = "";
          "on-click" = "pkill wofi || wofi --show drun --term=$TERMINAL --width=2[% --height=50% --columns 1 -I";
          "tooltip" = false;
        };

        "clock" = {
          "format" = "  {:%H:%M}";
        };

        "clock#date" = {
          "format" = "  {:%A, %d %B, %Y}";
        };

        "network" = {
          "format-wifi" = "󰤨  {signalStrength}%";
          "format-ethernet" = "󰈀  {signalStrength}%";
          "format-disconnected" = "󰤫 ";
          "on-click" = "$TERMINAL -e nmtui";
        };

        "battery" = {
          "bat" = "BAT0";
          "adapter" = "ADP0";
          "interval" = 60;
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "max-length" = 10;
          "format" = "{icon} {capacity}%";
          "format-warning" = "{icon} {capacity}%";
          "format-critical" = "{icon} {capacity}%";
          "format-charging" = "  {capacity}%";
          "format-plugged" = "  {capacity}%";
          "format-alt" = "{icon} {capacity}%";
          "format-full" = "  100%";
          "format-icons" = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        };

        "pulseaudio" = {
          "format" = "{icon} {volume}%";
          "format-bluetooth" = "{icon}  {volume}%";
          "format-bluetooth-muted" = "婢  muted";
          "format-muted" = "婢 muted";
          "format-icons" = {
            "headphone" = "󰋋";
            "hands-free" = "󰥰";
            "headset" = "󰋋";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" "" ];
          };
          "on-click-right" = "pavucontrol";
          "on-click" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };

        "custom/powermenu" = {
          "format" = "";
          "on-click" = "hyprctl dispatch exit";
          "tooltip" = false;
        };
      };
    };

    style = ''
      @define-color bg_dim #efebd4;
      @define-color bg0 #fdf6e3;
      @define-color bg1 #f4f0d9;
      @define-color bg2 #efebd4;
      @define-color bg3 #e6e2cc;
      @define-color bg4 #e0dcc7;
      @define-color bg5 #bdc3af;
      @define-color bg_visual #eaedc8;
      @define-color bg_red #fbe3da;
      @define-color bg_green #f0f1d2;
      @define-color bg_blue #e9f0e9;
      @define-color bg_yellow #faedcd;
      @define-color fg #5c6a72;
      @define-color red #f85552;
      @define-color orange #f57d26;
      @define-color yellow #dfa000;
      @define-color green #8da101;
      @define-color aqua #35a77c;
      @define-color blue #3a94c5;
      @define-color purple #df69ba;
      @define-color grey0 #a6b0a0;
      @define-color grey1 #939f91;
      @define-color grey2 #829181;

      * {
        font-family: JetBrainsMono Nerd Font, FontAwesome;
        font-size: 16px;
        font-weight: bold;
      }

      window#waybar {
        background-color: @fg;
        color: @bg0;
        transition-property: background-color;
        transition-duration: 0.5s;
        border-radius: 0px 0px 15px 15px;
        transition-duration: .5s;

        border-bottom-width: 5px;
        border-bottom-color: #2e3538;
        border-bottom-style: solid;
      }

      #custom-launcher,
      #clock,
      #clock-date,
      #workspaces,
      #pulseaudio,
      #network,
      #battery,
      #custom-powermenu {
        background-color: @bg0;
        color: @fg;

        padding-left: 10px;
        padding-right: 10px;
        margin-top: 7px;
        margin-bottom: 12px;
      	border-radius: 10px;

        border-bottom-width: 5px;
        border-bottom-color: @bg5;
        border-bottom-style: solid;
      }

      #workspaces {
        padding: 0px;
      }

      #workspaces button.active {
        background-color: @blue;
        color: @bg0;

      	border-radius: 10px;

        margin-bottom: -5px;

        border-bottom-width: 5px;
        border-bottom-color: #1c4a62;
        border-bottom-style: solid;
      }

      #custom-launcher {
        background-color: @green;
        color: @bg0;
        border-bottom-color: #465000;

        margin-left: 12px;
        padding-left: 15px;
        padding-right: 21px;
      }

      #custom-powermenu {
        background-color: @red;
        color: @bg0;
        border-bottom-color: #9e0906;

        margin-right: 15px;
        padding-left: 20px;
        padding-right: 23px;
      }
    '';
  };
}
