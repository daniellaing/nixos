{config, ...}: {
  hosts.expat.modules.nginx = {
    imports = with config.modules; [nginx];

    services.nginx = {
      # Testing
      virtualHosts.localhost = {
        locations."/" = {
          return = "200 '<html><body>It works</body></html>";
          extraConfig = "default_type text/html;";
        };
      };
    };
  };
}
