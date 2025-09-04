{lib, ...}: {
  imports = [
    ./nixos
    ./home-manager
  ];

  options.cooked = {
    preload = {
      server = lib.mkEnableOption "server style configuration";
      desktop = lib.mkEnableOption "desktop style configuration";
    };
  };
}
