{ inputs, config, ... }:

{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
    };
    nftables.enable = true;
  };
}
