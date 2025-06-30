{pkgs, ...}: {
  home-manager.sharedModules = [
    ({config, ...}: {
      # Share ssh key with Windows
      home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink /mnt/c/Users/daniel.laing/.ssh;

      programs.git = {
        package = pkgs.gitSVN;
        userEmail = "daniel.laing@accord-esl.com";
        signing = {
          key = "2AD34BF0A9D2299CBC449D37912B6C10891E04BA";
        };
      };
    })
  ];
}
