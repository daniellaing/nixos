{
  inputs,
  lib,
  ...
}: let
  hm_users = ["daniel"];
in {
  imports =
    [
      inputs.nixos-wsl.nixosModules.default
    ]
    ++ lib.flatten (map (user: lib.optional (lib.pathExists ../../users/${user}) ../../users/${user}) hm_users);
  cooked-preload = "desktop";

  wsl = {
    enable = true;
    defaultUser = "daniel";
  };

  networking.nftables.enable = lib.mkForce false;
}
