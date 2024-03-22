{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

  environment.systemPackages = with pkgs; [
    xclip
    dmenu
  ];
}
