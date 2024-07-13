{lib, ...}: {
  imports = [
    ./fonts.nix
    ./nix-index.nix
    ./scripts.nix
    ./vm.nix
  ];

  fonts.enable = lib.mkDefault true;
  scripts = {
    enable = lib.mkDefault true;
    nix-helpers = lib.mkDefault true;
  };
}
