{
  modules.sshd = {
    services.openssh = {
      enable = true;
      openFirewall = true; # Opens the specified ports
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
