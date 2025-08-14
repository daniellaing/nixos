{
  pkgs ?
    import <nixpkgs> {
      config = {};
      overlays = [];
    },
  ...
}: {
  default = {
    commands = [
      {
        package = "nh";
        help = "the Nix helper";
      }
      # {
      #   package = "configure";
      #   help = "configure NixOS";
      # }
      # {
      #   package = "update-system";
      #   help = "update NixOS";
      # }
    ];
  };
}
