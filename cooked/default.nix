{lib, ...}: {
  imports = [
    ./fonts.nix
    ./network.nix
    ./nix-index.nix
    ./scripts.nix
    ./services
    ./vm.nix
  ];

  cooked = {
    fonts.enable = lib.mkDefault true;
    network.enable = lib.mkDefault true;
    scripts = {
      enable = lib.mkDefault true;
      nix-helpers = lib.mkDefault true;
    };
  };
}
