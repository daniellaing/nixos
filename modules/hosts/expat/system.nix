{config, ...}: {
  hosts.expat.domain = "test.com";

  hosts.expat.modules.system = {
    system.stateVersion = "26.05"; # Do not change, ever
    imports = with config.modules; [
      core

      sshd

      # Testing
      radicale
      vikunja
    ];
  };
}
