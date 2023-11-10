{ hyprland, config, pkgs, ... }:

{
  imports = [
    hyprland.homeManagerModules.default
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # settings = {
    #   input = {
    #     kblayout = [ "gb" "us" ];
    #     kbvariant = [ "uk" "dvorak" ];
    #     kboptions = caps:swapescape,grp:ctrls_toggle;
    #   };
    # };
    settings = { };
  };
}
