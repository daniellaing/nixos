{lib, ...}: {
  imports = [
    ./fonts.nix
    ./nix-index.nix
    ./vm.nix
  ];

  fonts.enable = lib.mkDefault true;
}
