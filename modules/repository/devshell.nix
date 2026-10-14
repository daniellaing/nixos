{inputs, ...}: {
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
  };

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
