{ ... }:

{
  services.xserver.displayManager = {
    sddm = {
      enable = true;
      autoNumLock = true;
    };
  };
}
