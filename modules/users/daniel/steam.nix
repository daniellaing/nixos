{
  users.daniel.steam = {pkgs, ...}: {
    home-manager.users.daniel = {
      home.packages = with pkgs; [steam];
    };
  };
}
