{inputs, ...}: {
  hosts.wsl.modules.hardware = {
    imports = [inputs.nixos-wsl.nixosModules.default];

    nixpkgs.hostPlatform = "x86_64-linux";

    wsl = {
      enable = true;
      defaultUser = "daniel";
      startMenuLaunchers = true;
    };
  };
}
