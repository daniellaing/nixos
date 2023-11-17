{ inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.default
  ];

  sops = {
    defaultSopsFile = ../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/daniel/.config/sops/age/keys.txt";
  };
}
