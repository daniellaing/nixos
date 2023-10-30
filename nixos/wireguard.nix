{ config, pkgs, ... }:

{
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "172.16.0.2/24" ];
      listenPort = 51820;
      privateKeyFile = "/home/daniel/wireguard-keys/private";
      peers = [{
        publicKey = "y5w4do7Ih6eh2LnbAnEREnLTdAAcBOQXt5vsk60Nqxw=";
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "daniellaing.com:51820";
        persistentKeepalive = 25;
      }];
    };
  };

  networking.firewall = {
    logReversePathDrops = true;
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-filter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-filter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-filter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-filter -p udp -m udp --dport 51820 -j RETURN || true
    '';
  };
}
