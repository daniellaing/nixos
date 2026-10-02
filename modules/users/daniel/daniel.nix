{config, ...}: {
  users.daniel.core = {pkgs, ...}: {
    imports = with config.modules; [
      home-manager
    ];

    home-manager.users.daniel.home = {
      username = "daniel";
      homeDirectory = "/home/daniel";
    };

    environment.systemPackages = [pkgs.asciiquarium];
  };
}
