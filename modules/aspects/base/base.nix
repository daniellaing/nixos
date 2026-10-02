{
  config,
  inputs,
  rootPath,
  ...
}: {
  modules.base = {pkgs, ...}: {
    imports = [inputs.sops-nix.nixosModules.default] ++ (with config.modules; []);

    # ---   GnuPG   ---
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    # ---   Locate   ---
    services.locate = {
      enable = true;
      interval = "hourly";
      pruneBindMounts = true;
    };

    # ---   Printing   ---
    services = {
      printing.enable = true;

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    # --- Sops   ---
    sops = {
      defaultSopsFile = rootPath + "/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/daniel/.config/sops/age/keys.txt"; # TODO: Improve this line
    };

    # ---   Other packages   ---
    environment.systemPackages = with pkgs; [
      ripgrep
      unzip
      wget
    ];
  };
}
