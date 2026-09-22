{
  inputs,
  lib,
  config,
  ...
} @ args: let
  users = ["sysadmin"];
in {
  home-manager.users = lib.mkHomeUsers ../../users args users;
  # cooked.preload.server = true;
  system.stateVersion = "23.05"; # Do not change.

  users = {
    users."sysadmin" = {
      isNormalUser = true;
      initialPassword = "password";
      group = "sysadmin";
    };

    groups."sysadmin" = {};
  };

  virtualisation.vmVariant = {
    virtualisation.forwardPorts = [
      # forward local port 2222 -> 22, to ssh into the VM
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }

      # forward local port 80 -> 10.0.2.10:80 in the VLAN
      {
        from = "guest";
        guest.address = "10.0.2.10";
        guest.port = 80;
        host.address = "127.0.0.1";
        host.port = 80;
      }
    ];
  };
}
