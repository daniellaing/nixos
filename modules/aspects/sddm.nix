{
  modules.sddm = {pkgs, ...}: {
    # TODO: Test this
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        theme = "${pkgs.sddm-chili-theme}";
      };
    };
  };
}
