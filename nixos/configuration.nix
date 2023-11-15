{ config, pkgs, lib, ... }:

{
  system.stateVersion = "23.05"; # Did you read the comment?

  programs.hyprland.enable = true;

  imports =
    [
      # ./mathematica.nix
      ./email
      ./fonts.nix
      ./kde.nix
      ./nix-locate.nix
      ./programs.nix
      ./services
      ./X11.nix
      ./zsh.nix
    ];

  # Enable Nix commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      extraEntries =
        ''
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

  # Keep system up to date
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # Clean unused packages
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Enable networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.daniel = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Daniel Laing";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.dbus.packages = [
    pkgs.dbus.out
    config.system.path
  ];
  environment.pathsToLink = [ "/etc/dbus-1" "/share/dbus-1" ];

  security.polkit.enable = true;

  programs.ssh.askPassword = "/nix/store/pg42226jhbpjp47s03h0glzxyxq36h6i-ksshaskpass-5.27.7/bin/ksshaskpass";
  programs.adb.enable = true;

  # SDDM
  services.xserver.displayManager.sddm.enable = true;

  # Keep a list of all installed packages
  environment.etc."current-system-packages".text =
    let
      packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
