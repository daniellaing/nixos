inputs:
inputs.flake-parts.lib.mkFlake {inherit inputs;} {
  _module.args.rootPath = ./.;
  flake.templates = import ./templates inputs;
  imports = [(inputs.import-tree ./modules)];

  debug = true;
}
