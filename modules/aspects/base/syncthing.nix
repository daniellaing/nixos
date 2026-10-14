{
  modules.syncthing = {
    # I want to run syncthing as a user service
    # So we leave the service disabled and instead let each user configure their own syncthing.
    # But we must still manually open the default ports
    networking.firewall = {
      allowedTCPPorts = [22000];
      allowedUDPPorts = [21027 22000];
    };
  };
}
