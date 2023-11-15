{ ... }:

{
  services.xserver.displayManager = {
    sddm = {
      enable = true;
      autoNumlock = true;
    };
  };
}
