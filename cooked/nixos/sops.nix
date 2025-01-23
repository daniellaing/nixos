{
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.cooked.sops;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.cooked.sops = {
    enable = lib.mkEnableOption "sops secret managment";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/daniel/.config/sops/age/keys.txt";
      secrets.svn-passwd = {
        owner = config.users.users.daniel.name;
        group = config.users.users.daniel.group;
      };
    };
  };
}
