{ hyprland, config, pkgs, ... }:

{
  imports = [
    hyprland.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    hyprpaper
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      input {
              kb_layout = gb, us
              kb_variant = uk, dvorak
              kb_options = caps:swapescape,grp:ctrls_toggle
              numlock_by_default = true
              follow_mouse = 1
          }

      $MOD = SUPER
      bind = $MOD, return, exec, kitty
      bind = $MOD, backspace, exit,
    '';
  };
}
