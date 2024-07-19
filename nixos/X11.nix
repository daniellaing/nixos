{pkgs, ...}: {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      xclip
      dmenu
      ;
  };
}
