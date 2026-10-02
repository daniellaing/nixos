{
  inputs,
  rootPath,
  ...
}: {
  modules.sops = {
    imports = [inputs.sops-nix.nixosModules.default];

    sops = {
      defaultSopsFile = rootPath + "/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/daniel/.config/sops/age/keys.txt"; # TODO: Improve this line
    };
  };
}
