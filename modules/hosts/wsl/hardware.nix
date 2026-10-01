{
  inputs,
  config,
  ...
}: {
  hosts.wsl.modules.hardware = {
    imports = [inputs.nixos-wsl.nixosModules.default config.modules.nix];

    nixpkgs.hostPlatform = "x86_64-linux";

    wsl = {
      enable = true;
      defaultUser = "daniel";
      startMenuLaunchers = true;
    };
  };
}
