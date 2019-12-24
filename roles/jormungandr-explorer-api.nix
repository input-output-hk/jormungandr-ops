{ lib, pkgs, config, resources, name, globals, nodes, ... }: {
  imports = [ ./jormungandr-relay.nix ];

  services.jormungandr.enable = true;
  systemd.services.jormungandr.after = [ "wg-quick-w0.service" ];
  services.jormungandr.enableExplorer = true;

  services.jormungandr.rest.listenAddress = lib.mkForce "${config.node.wireguardIP}:3001";
  networking.firewall.allowedTCPPorts = [ 3001 ];

  networking.wg-quick.interfaces.wg0.peers = [
    {
      allowedIPs = [ "${nodes.explorer.config.node.wireguardIP}/32" ];
      publicKey = lib.fileContents ../secrets/wireguard/explorer.public;
      presharedKeyFile = "/run/keys/wg_shared";
      endpoint = "explorer-ip:17777";
      persistentKeepalive = 25;
    }
  ];
}
