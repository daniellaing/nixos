{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {...}: {
    devshells.default = {
      commands = [
        {
          package = "nh";
          help = "the Nix helper";
        }
      ];
    };
  };
}
