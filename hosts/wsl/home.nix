{
  lib,
  pkgs,
  ...
}: {
  home-manager.sharedModules = [
    ({config, ...}: {
      # Share ssh key with Windows
      home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink /mnt/c/Users/daniel.laing/.ssh;

      programs.git = {
        package = lib.mkForce pkgs.gitSVN;
        userEmail = lib.mkForce "daniel.laing@accord-esl.com";
      };
    })
  ];
}
