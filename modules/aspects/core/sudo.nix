{
  modules.sudo = {
    security = {
      polkit.enable = true;
      sudo.extraRules = [
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
    };
  };
}
