{
  inputs,
  config,
  ...
}: {
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Syncthing port: 22000
      allowedTCPPorts = [22000];
      allowedUDPPorts = [22000];
    };
    nftables.enable = true;
  };
}
