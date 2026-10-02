{config, ...}: {
  hosts.dellG5.users = {
    daniel = {
      imports = with config.users.daniel; [
        core
        base
        gui

        development
        music
        zsh
      ];
      users.users.daniel = {
        isNormalUser = true;
        description = "Daniel Laing";
        extraGroups = [
          "wheel"
        ];
      };
    };
  };
}
