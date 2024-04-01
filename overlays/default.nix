{inputs, ...}: {
  stable-packages = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = prev.system;
      config.allowUnfree = true;
    };
  };
}
