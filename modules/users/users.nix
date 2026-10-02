{
  lib,
  config,
  ...
}: {
  options = {
    users = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
      description = ''
        Set of user configuration modules.
      '';
    };
  };

  config = {
    flake.nixosModules = lib.concatMapAttrs (user: modules:
      lib.mapAttrs' (name: module:
        lib.nameValuePair "${user}-${name}"
        module)
      modules)
    config.users;
  };
}
