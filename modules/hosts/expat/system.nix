{config, ...}: {
  hosts.expat.modules.system = {
    system.stateVersion = "26.05"; # Do not change, ever
    imports = with config.modules; [
      core
    ];

    virtualisation.vmVariant = {
      boot.kernelParams = ["net.ifnames=0"];

      virtualisation = {
        memorySize = 4096;
        cores = 2;
        diskSize = 20480;
        graphics = false;
      };
    };
  };
}
