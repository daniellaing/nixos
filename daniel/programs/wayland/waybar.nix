{ config, pkgs, ... }:
with config.colorScheme.colors;
{
  programs.waybar = {
    enable = true;
    package = (pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    }));
    settings.mainBar = {
      "position" = "top";
      "layer" = "top";
      "height" = 35;
      "margin-top" = 0;
      "margin-bottom" = 0;
      "margin-left" = 0;
      "margin-right" = 0;

      "modules-left" = [
        "custom/launcher"
      ];
      "modules-center" = [
        "hyprland/workspaces"
      ];
      "modules-right" = [
        "tray"
        "pulseaudio"
        "network"
        "battery"
        "clock"
      ];

      "hyprland/workspaces" = {
        "on-click" = "activate";
        "all-outupts" = true;
        "sort-by-number" = true;
        "on-scroll-up" = "hyprctl dispatch workspace e+1";
        "on-scroll-down" = "hyprctl dispatch workspace e-1";
        "smooth-scrolling-threshold" = 1;
      };

      "custom/launcher" = {
        "interval" = "once";
        "format" = "";
        "on-click" = "pkill wofi || wofi --show drun --term=$TERMINAL --width=55% --height=50% --columns 1 -I";
        "tooltip" = false;
      };

      "clock" = {
        "format" = "  {:%a, %e %b %H:%M}";
      };

      "network" = {
        "format-wifi" = "󰤨  {signalStrength}%";
        "format-ethernet" = "󰈀  {signalStrength}%";
        "format-disconnected" = "󰤫 ";
        "on-click" = "$TERMINAL -e nmtui";
        "tooltip-format" = "Connected to {essid} {ifname} via {gwaddr}";
      };

      "battery" = {
        "states" = {
          "warning" = 30;
          "critical" = 15;
        };
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
        "format-bluetooth-muted" = "󰝟  muted";
        "format-muted" = "󰝟 muted";
        "format-icons" = {
          "headphone" = "󰋋";
          "hands-free" = "󰥰";
          "headset" = "󰋋";
          "phone" = "";
          "portable" = "";
          "car" = "";
          "default" = [ "" "" "" ];
        };
        "on-click" = "pavucontrol";
        "on-click-right" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        border: none;
        border-radius: 0px;
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
      }

      #workspaces {
        background: #${base00};
        margin: 5px 5px;
        padding: 8px 5px;
        border-radius: 16px;
        color: #${base06};
      }
      #workspaces button {
        color: #${base06};
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        background: transparent;
        transition: all 0.3s ease-in-out;
      }

      #workspaces button.active {
        background: #${base0B};
        color: #${base00};
        border-radius: 16px;
        min-width: 40px;
        background-size: 400% 400%;
        transition: all 0.3s ease-in-out;
      }

      #workspaces button:hover {
        background: #${base0D};
        color: #${base00};
        border-radius: 16px;
        min-width: 50px;
        background-size: 400% 400%;
      }

      #tray,
      #pulseaudio,
      #network,
      #battery {
        background: #${base00};
        color: #${base05};
        font-weight: bold;
        margin: 5px 0px;
        border-radius: 10px 24px 10px 24px;
        padding: 0 20px;
        margin-left: 7px;
      }
      #clock {
        background: #${base00};
        color: #${base05};
        border-radius: 0px 0px 0px 40px;
        padding: 10px 10px 15px 25px;
        margin-left: 7px;
        font-weight: bold;
        font-size: 16px;
      }
      #custom-launcher {
        background: #${base00};
        color: #${base06};
        border-radius: 0px 0px 40px 0px;
        margin: 0px;
        padding: 0px 35px 0px 15px;
        font-size: 28px;
      }

      @keyframes warning {
          100% {
            background: #${base00};
          }
          0% {
            background: #${base08};
          }
      }
      #battery.warning {
        animation: warning 1s infinite;
      }
    '';
  };
}
