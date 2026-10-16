{lib, ...}: {
  hosts.expat.modules.hardware = {modulesPath, ...}: {
    # VM-only target: real hardware config will be generated later on the
    # target machine with `nixos-generate-config`.
    imports = [(modulesPath + "/profiles/qemu-guest.nix")];

    nixpkgs.hostPlatform = "x86_64-linux";

    boot = {
      loader.grub = {
        enable = true;
        device = "/dev/vda";
      };
      growPartition = true;
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    # Remote access
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    services.fstrim.enable = true;
  };
}
