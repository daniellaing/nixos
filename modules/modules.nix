{lib, ...}: {
  options = {
    modules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      description = ''
        Set of defined NixOS modules.
      '';
    };
  };
}
