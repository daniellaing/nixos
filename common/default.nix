{lib, ...}: {
  imports = [
    ./fonts.nix
    ./vm.nix
  ];

  fonts.enable = lib.mkDefault true;
}
