{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.cooked.vm;
in {
  options.cooked.vm = {
    enable = lib.mkEnableOption "virtualisation";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.enable = true;
          ovmf.packages = [pkgs.OVMFFull.fd];
        };
      };
      spiceUSBRedirection.enable = true;
    };

    services.spice-vdagentd.enable = true;

    programs = {
      virt-manager = {
        enable = true;
      };
    };

    environment.systemPackages = [
      pkgs.virtiofsd
    ];

    networking.firewall.trustedInterfaces = ["virbr0"];
  };
}
