{lib, ...}: {
  hosts.dellG5.modules.hardware = {
    config,
    pkgs,
    ...
  }: {
    nixpkgs.hostPlatform = "x86_64-linux";

    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "sd_mod"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel" "acpi_call"];
      extraModulePackages = builtins.attrValues {inherit (config.boot.kernelPackages) acpi_call;};
      kernelParams = ["acpi_osi=Linux-Dell-Video"];

      # Bootloader
      loader = {
        systemd-boot.enable = false;
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
          extraEntries = ''
            menuentry "Reboot" {
              reboot
            }

            menuentry "Shut Down" {
              halt
            }
          '';
          theme = pkgs.stdenv.mkDerivation {
            pname = "distro-grub-themes";
            version = "3.1";
            src = pkgs.fetchFromGitHub {
              owner = "AdisonCavani";
              repo = "distro-grub-themes";
              rev = "v3.1";
              hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
            };
            installPhase = "cp -r customize/nixos $out";
          };
        };
      };
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/c44064c6-0a7f-4f17-aeef-1445ce58625d";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/1B43-DD2B";
      fsType = "vfat";
    };

    fileSystems."/home" = {
      device = "/dev/disk/by-uuid/a6364a7f-72ed-4148-842a-572e6962bf8e";
      fsType = "ext4";
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/664e0c1a-b532-46bd-8a14-1f63fb74e2c4";}
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

    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Cooling and battery managment
    services.thermald.enable = true;
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;
      };
    };

    services.libinput.enable = true;

    # NVIDIA Stuff
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
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

    services.xserver.videoDrivers = lib.mkDefault ["nvidia"];
  };
}
