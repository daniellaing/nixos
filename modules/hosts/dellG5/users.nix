{config, ...}: {
  hosts.dellG5.users = {
    daniel = {
      imports = with config.users.daniel; [
        core
        base
        gui

        development
        email
        music
        zsh
      ];

      programs.thunderbird.enable = true;
      users.users.daniel = {
        isNormalUser = true;
        description = "Daniel Laing";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };
    };
  };
}
