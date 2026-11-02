{config, ...} @ outer: {
  modules.radicale = {host, ...}: let
    port = 5232;
  in {
    imports = with outer.config.modules; [nginx];

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = ["0.0.0.0:${toString port}" "[::]:${toString port}"];
        auth.type = "none"; # TODO: Proper authentication
      };
    };

    services.nginx = {
      virtualHosts."cal.${host.domain}" = {
        locations."/".proxyPass = "http://localhost:${toString port}";
      };
    };
  };
}
