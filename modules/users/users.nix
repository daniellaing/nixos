{lib, ...}: {
  options = {
    users = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
      description = ''
        Set of user configuration modules.
      '';
    };
  };
}
