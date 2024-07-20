{
  imports = [
    ./dbus.nix
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

  # New
  # services.display-manager.enable = true;
}
