{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./accounts.nix
    ./pass.nix
    ./neomutt.nix
  ];

  programs = {
    mbsync.enable = true;
    msmtp.enable = true;
    notmuch.enable = true;
    thunderbird = {
      enable = true;
      profiles.daniel = {
        isDefault = true;
      };
    };
  };
}
