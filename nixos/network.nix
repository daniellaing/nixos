{ inputs, config, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };
}
