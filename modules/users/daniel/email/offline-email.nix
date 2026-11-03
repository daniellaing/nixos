{
  users.daniel.offlineEmail = {
    home-manager.users.daniel = {
      services.mbsync = {
        enable = true;
      };

      programs = {
        mbsync.enable = true;
        msmtp.enable = true;
        notmuch.enable = true;
      };
    };
  };
}
