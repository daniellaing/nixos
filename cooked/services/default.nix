{lib, ...}: {
  cooked.locate.enable = lib.mkDefault true;

  imports = [
    ./display-manager.nix
    ./locate.nix
    ./printing.nix
    ./sound.nix
  ];
}
