{
  imports = [
    ./hardware.nix
  ];

  cooked = {
    sound.enable = true;
    display-manager.enable = true;
    printing.enable = true;
  };
}
