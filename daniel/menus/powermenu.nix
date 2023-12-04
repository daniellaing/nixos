{ pkgs, ... }:
let
  powermenu = pkgs.writeShellApplication {
    name = "powermenu";
    runtimeInputs = with pkgs; [ wofi waylock hyprland ];
    text = ''
      options=(" Lock" " Sleep" "󰍃 Logout" " Reboot" "󰐥 Shutdown")
      prompt="$(uptime | sed -r 's/.*up ([^,]*),.*/\1/')"
      sel="$(printf '%s\n' "''${options[@]}" | wofi --show=dmenu -p "$prompt")"

      case $sel in
          *Shutdown*)
              systemctl poweroff
          ;;

          *Reboot*)
              systemctl reboot
          ;;

          *Sleep*)
              systemctl suspend
          ;;

          *Lock*)
              waylock
          ;;

          *Logout*)
              hyprctl dispatch exit
          ;;

          *)
              echo Unknown option
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    powermenu
  ];
}
