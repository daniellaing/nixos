{
  self,
  config,
  inputs,
  lib,
  ...
}: let
  shortHash = self.shortRev or "dirty";
in {
  options = {
    hosts = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.submodule ({
        config,
        name,
        ...
      }: {
        options = {
          name = lib.mkOption {
            readOnly = true;
            type = lib.types.str;
            default = name;
          };

          users = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.deferredModule;
            description = ''
              Set of users in the host.
            '';
            default = {};
            apply = lib.mapAttrs (user: module: {
              key = "hosts:${name}:users:${user}";
              imports = [module];
            });
          };

          modules = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.deferredModule;
            description = ''
              Set of modules in the host.
            '';
            default = {};
            apply = lib.mapAttrs (mname: module: {
              key = "hosts:${name}:modules:${mname}";
              imports = [module];
            });
          };

          # The final, evaluated NixOS system config
          configuration = lib.mkOption {
            readOnly = true;
            type = lib.types.attrs;
            default = inputs.nixpkgs.lib.nixosSystem {
              modules =
                (lib.attrValues config.modules) # Host NixOS modules
                ++ (lib.attrValues config.users) # User NixOS modules
                ++ [
                  # Default modules
                  {
                    networking.hostName = name;
                    system = {
                      configurationRevision = shortHash;
                      nixos.label = shortHash;
                    };
                  }
                ];
            };
          };
        };
      }));
    };
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs (_hostname: {configuration, ...}: configuration) config.hosts;

    checks = lib.mkMerge (lib.mapAttrsToList (host: {configuration, ...}:
      lib.setAttrByPath
      [configuration.pkgs.stdenv.hostPlatform.system host]
      configuration.config.system.build.toplevel)
    config.hosts);
  };
}
