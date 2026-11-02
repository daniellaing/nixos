{lib, ...}: {
  hosts.expat.modules.vm = lib.mkMerge [
    {
      virtualisation.vmVariant = {
        boot.kernelParams = ["net.ifnames=0"];

        virtualisation = {
          memorySize = 4096;
          cores = 2;
          diskSize = 20480;
          graphics = false;
        };
      };
    }

    (
      lib.pipe [3000 5232 80 443] [
        (lib.map (port: {
          virtualisation.vmVariant = {
            virtualisation.forwardPorts = [
              {
                from = "host";
                host.address = "127.0.0.1";
                host.port = port + 1000;
                guest.port = port;
              }
            ];
            networking.firewall.allowedTCPPorts = [port];
          };
        }))
        lib.mkMerge
      ]
    )
  ];
}
