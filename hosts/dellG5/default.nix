{lib, ...}: let
  hm_users = ["daniel"];
in {
  imports =
    [
      ./hardware.nix
    ]
    ++ lib.flatten (map (user: lib.optional (lib.pathExists ../../users/${user}) ../../users/${user}) hm_users);
  cooked-preload = "desktop";
}
