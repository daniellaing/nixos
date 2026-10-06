{lib, ...}: {
  options = {
    modules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      description = ''
        Set of defined NixOS modules.
      '';
      apply = lib.mapAttrs (name: module: {
        key = "modules:${name}";
        imports = [module];
      });
    };
  };
}
