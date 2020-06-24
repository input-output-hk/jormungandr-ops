{ lib, pkgs, config, resources, name, globals, nodes, ... }:
let
  pkgs = import ../nix { };
  inherit (pkgs.lib) mkForce;
  # jormungandr = pkgs.jormungandrLib.packages.v0_9_0;
in
{
  imports = [ ./jormungandr-relay.nix ];

  services.jormungandr = {
    enable = true;
    enableRewardsReportAll = true;
  };
  systemd.services.jormungandr.after = [ "wg-quick-w0.service" ];
  services.jormungandr.enableRewardsLog = true;
  services.jormungandr.enableExplorer = true;
  services.jormungandr-reward-api = {
    enable = true;
    port = 3003;
    host = "${config.node.wireguardIP}";
  };

  services.jormungandr.rest.listenAddress = lib.mkForce "${config.node.wireguardIP}:3001";
  networking.firewall.allowedTCPPorts = [ 3001 3003 ];

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
