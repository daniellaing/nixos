{ config, pkgs, ... }:

{
  # Install needed packages
  environment.systemPackages = with pkgs; [
    neomutt
    isync
    msmtp
    pass
    curl
    lynx
    gnupg
    notmuch

    (import ./sync-email.nix { inherit pkgs; })
    (import ./get-mailboxes.nix { inherit pkgs; })
    (import ./neomutt-account-switcher.nix { inherit pkgs; })
  ];
}
