{
  inputs,
  pkgs,
  lib,
  config,
  ...
} @ args: let
  users = ["daniel"];
in {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ./home.nix
  ];

  home-manager.users = lib.mkHomeUsers ../../users args users;

  cooked.preload.desktop = true;

  system.stateVersion = "23.05"; # Do not change.

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
