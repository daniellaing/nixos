{config, ...} @ outer: {
  hosts.expat.modules.nginx = {host, ...}: {
    imports = with outer.config.modules; [nginx];

    services.nginx = {
      # Testing
      virtualHosts."${host.domain}" = {
        locations."/" = {
          return = "200 '<html><body>It works</body></html>'";
          extraConfig = "default_type text/html;";
        };
      };
    };
  };
}
