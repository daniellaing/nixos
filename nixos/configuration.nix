{
  config,
  pkgs,
  lib,
  ...
}: {
  # Syncthing
  networking.firewall = {
    allowedTCPPorts = [22000];
    allowedUDPPorts = [21027 22000];
  };

  imports = [
    ./email
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.daniel = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Daniel Laing";
    extraGroups = [
      "video"
      "networkmanager"
      "wheel"
      "adbusers"
      "libvirtd"
      "syncthing"
    ];
  };

  security.polkit.enable = true;
  security.sudo.extraRules = [
    {
      groups = ["wheel"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/wrappers/bin/mount";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/wrappers/bin/umount";
          options = ["SETENV" "NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/loadkeys";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];

  programs.ssh.askPassword = "/nix/store/pg42226jhbpjp47s03h0glzxyxq36h6i-ksshaskpass-5.27.7/bin/ksshaskpass";

  # Keep a list of all installed packages
  environment.etc."current-system-packages".text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in
    formatted;
}
