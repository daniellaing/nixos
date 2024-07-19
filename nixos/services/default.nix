{
  imports = [
    ./dbus.nix
    ./display-manager.nix
    ./keyring.nix
    ./locate.nix
    ./printing.nix
    ./sound.nix
  ];

  # Syncthing
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
  };
}
