{ config, name, nodes, ... }:
let
  sources = import ../nix/sources.nix;

  pkgs = import ../nix { };
  inherit (pkgs) jormungandr-cli jormungandr;

  trustedPeersAddresses = __filter (e: e != null) (__attrValues (__mapAttrs
    (nodeName: node:
      if nodeName == name then
        null
      else
        "/ip4/${node.config.networking.privateIPv4}/tcp/3000") nodes));
in {
  imports = [ (sources.jormungandr-nix + "/nixos") ];

  services.jormungandr = {
    enable = true;
    withBackTraces = true;
    package = jormungandr;
    jcliPackage = jormungandr-cli;
    rest.cors.allowedOrigins = [ ];
    publicAddress = "/ip4/${config.networking.privateIPv4}/tcp/3000";
    listenAddress = "/ip4/${config.networking.privateIPv4}/tcp/3000";
    rest.listenAddress = "${config.networking.privateIPv4}:3001";
    logger = { output = "journald"; };
    inherit trustedPeersAddresses;
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  environment.variables.JORMUNGANDR_RESTAPI_URL =
    "http://${config.services.jormungandr.rest.listenAddress}/api";
}
