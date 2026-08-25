{
  lib,
  pkgs,
  ...
} @ args: let
  users = ["daniel"];
in {
  imports = [
    ./hardware.nix
  ];

  home-manager.users =
    lib.genAttrs
    (builtins.filter (user: lib.pathExists ../../users/${user}) users)
    (user: import ../../users/${user} args);

  cooked.preload.desktop = true;

  system.stateVersion = "23.05"; # Do not change.

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      extraEntries = ''
        menuentry "Reboot" {
          reboot
        }

        menuentry "Shut Down" {
          halt
        }
      '';
      theme = pkgs.stdenv.mkDerivation {
        pname = "distro-grub-themes";
        version = "3.1";
        src = pkgs.fetchFromGitHub {
          owner = "AdisonCavani";
          repo = "distro-grub-themes";
          rev = "v3.1";
          hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
        };
        installPhase = "cp -r customize/nixos $out";
      };
    };
  };
}
