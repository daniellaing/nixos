{config, ...}: {
  users.daniel.syncthing = {
    imports = with config.modules; [syncthing];
    users.users.daniel.extraGroups = ["syncthing"];
    home-manager.users.daniel.services.syncthing = {
      enable = true;
      overrideDevices = false;
      overrideFolders = false;

      settings = {
        devices = {
          "Pixel 7 Pro".id = "6GZOFNC-HLV2GSE-U6XSWOE-32BLTBX-SX6CLGC-AZBBMHJ-CLBPDEJ-WB5MSQL";
          "Daniels-iPhone".id = "66EVUYI-UTGSPGL-ROIMXEE-PCI73ZR-B5K7K36-PVDZVMT-2JUA642-S5NDAQA";
        };
      };
    };
  };
}
