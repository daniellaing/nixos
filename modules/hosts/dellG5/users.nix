{config, ...}: {
  hosts.dellG5.users = {
    daniel = {pkgs, ...}: {
      imports = with config.users.daniel; [
        core
        base
        gui

        development
        music
        thunderbird
        offlineEmail
        zsh
      ];

      users.users.daniel = {
        isNormalUser = true;
        description = "Daniel Laing";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };

      home-manager.users.daniel = {
        home.packages = with pkgs; [steam];
      };
    };
  };
}
