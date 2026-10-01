{
  users.daniel.base = {pkgs, ...}: {
    environment.systemPackages = [pkgs.asciiquarium];
  };
}
