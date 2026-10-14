{
  config,
  lib,
  ...
}: {
  flake-file.inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
  };

  systems = lib.unique (lib.attrValues (lib.mapAttrs (hostname: {configuration, ...}:
    configuration.pkgs.stdenv.hostPlatform.system)
  config.hosts));
}
