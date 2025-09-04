{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  hm_users = ["daniel"];
in {
  imports =
    [
      inputs.nixos-wsl.nixosModules.default
      ./home.nix
    ]
    ++ lib.flatten (map (user: lib.optional (lib.pathExists ../../users/${user}) ../../users/${user}) hm_users);
  cooked.preload.desktop = true;

  wsl = {
    enable = true;
    defaultUser = "daniel";
    startMenuLaunchers = true;
  };

  networking.nftables.enable = lib.mkForce false;

  sops.secrets.svn-passwd = {
    owner = config.users.users.daniel.name;
    group = config.users.users.daniel.group;
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs);
  };
}
