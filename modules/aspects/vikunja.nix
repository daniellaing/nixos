{config, ...} @ outer: {
  modules.vikunja = {host, ...}: let
    # Default port is 3456
    port = 3456;
    hostname = "todo.${host.domain}";
  in {
    imports = with outer.config.modules; [nginx];

    services.vikunja = {
      enable = true;
      frontendScheme = "http";
      frontendHostname = hostname;
      inherit port;
    };

    services.nginx = {
      virtualHosts."${hostname}" = {
        locations."/" = {
          proxyPass = "http://localhost:${toString port}";
        };
      };
    };
  };
}
