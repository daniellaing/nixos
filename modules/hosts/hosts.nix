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
          };

          modules = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.deferredModule;
            description = ''
              Set of modules in the host.
            '';
            default = {};
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

  config = {
    flake.nixosConfigurations = lib.mapAttrs (_hostname: {configuration, ...}: configuration) config.hosts;

    flake.nixosModules =
      lib.concatMapAttrs (
        host: {
          configuration,
          modules,
          users,
          ...
        }:
          {"${host}-configuration" = configuration;}
          // lib.mapAttrs' (name: module: lib.nameValuePair "${host}-${name}" module) modules
          // lib.mapAttrs' (user: module: lib.nameValuePair "${host}-${user}" module) users
      )
      config.hosts;
  };
}
