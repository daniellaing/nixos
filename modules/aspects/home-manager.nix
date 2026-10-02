{inputs, ...}: {
  modules.home-manager = {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      startAsUserService = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      sharedModules = [
        ({osConfig, ...}: {
          home.stateVersion = osConfig.system.stateVersion;
          programs.home-manager.enable = true;
        })
      ];
    };
  };
}
