{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" "acpi_call" ];
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    kernelParams = [ "acpi_osi=Linux-Dell-Video" ];
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/18f8b16f-7d02-483f-a0fa-83b7af226709";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D08D-C40F";
      fsType = "vfat";
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/a6364a7f-72ed-4148-842a-572e6962bf8e";
      fsType = "ext4";
    };

  swapDevices = [
    { device = "/dev/disk/by-uuid/00703522-1162-4f5b-9d16-4f5ce3dce958"; }
  ];

  # Enable trim for SSD
  services.fstrim.enable = true;

  # Protect hard drive if laptop falls
  services.hdapsd.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.system-features = [
    "gccarch-skylake"
    "gcctune-skylake"
  ];
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Cooling managment
  services.thermald.enable = true;

  services.xserver.libinput.enable = true;

  # NVIDIA Stuff
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        offload.enable = true;
        offload.enableOffloadCmd = true;
      };
    };
  };

  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
}
