{ config, lib, name, nodes, resources, ... }:
let
  sources = import ../nix/sources.nix;

  pkgs = import ../nix { };
  inherit (pkgs.packages) pp;
  inherit (builtins) filter attrValues mapAttrs;

  #environment = pkgs.jormungandrLib.versions.v0_8_6;

  compact = l: filter (e: e != null) l;
  peerAddress = nodeName: node:
  if (
    node.config.node.isTrustedPoolPeer
    || node.config.node.isTrustedPeer
    || node.config.node.isExplorer
    || node.config.node.isStake
  ) && (nodeName != name) then
      {
        address = node.config.services.jormungandr.publicAddress;
        id = publicIds.${nodeName};
      }
    else
      null;
  trustedPeers = compact (attrValues (mapAttrs peerAddress nodes));

  trustedPeersFromJson = map (name:
    {
      address = "/ip4/${resources.elasticIPs."${name}-ip".address}/tcp/3000";
      id = publicIds.${name};
    }
    ) (__fromJSON (__readFile ../trusted.json));

  publicIds = __fromJSON (__readFile (../secrets/jormungandr-public-ids.json));
in {
  imports = [
    (sources.jormungandr-nix + "/nixos")
    ./monitoring-exporters.nix
    ./wireguard.nix
    ./common.nix
  ];
  disabledModules = [ "services/networking/jormungandr.nix" ];

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-jormungandr-${config.node.region}"
  ];

  services.jormungandr = {
    enable = true;
    withBackTraces = true;

    # trustedPeers = [];
    # inherit trustedPeers;
    trustedPeers = trustedPeersFromJson;
    package = pkgs.jormungandrLib.packages.v0_8_9.jormungandr-debug;
    jcliPackage = pkgs.jormungandrLib.packages.v0_8_9.jcli-debug;

    block0 = ../static/block-0.bin;
    rest.cors.allowedOrigins = [ ];
    publicAddress = if config.deployment.targetEnv == "ec2" then
      "/ip4/${resources.elasticIPs."${name}-ip".address}/tcp/3000"
    else
      "/ip4/${config.networking.publicIPv4}/tcp/3000";
    listenAddress = "/ip4/0.0.0.0/tcp/3000";
    rest.listenAddress = "${config.networking.privateIPv4}:3001";
    logger = {
      level = "info";
      output = "journald";
    };
    publicId = publicIds."${name}" or (abort "run ./scripts/update-jormungandr-public-ids.rb");
  };

  systemd.services.jormungandr = {
    serviceConfig = {
      MemoryMax = "3.5G";
      Restart = lib.mkForce "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  environment.variables.JORMUNGANDR_RESTAPI_URL =
    "http://${config.services.jormungandr.rest.listenAddress}/api";

  environment.systemPackages = with pkgs; [
    config.services.jormungandr.jcliPackage
    janalyze
    sendFunds
    checkTxStatus
  ];

  services.jormungandr-monitor = {
    enable = true;
    jcliPackage = config.services.jormungandr.jcliPackage;
    sleepTime = "30";
    #genesisYaml =
    #  if (builtins.pathExists ../static/genesis.yaml)
    #  then ../static/genesis.yaml
    #  else null;
  };

  services.journald = {
    rateLimitInterval = "30s";
    rateLimitBurst = 10000;
  };

  boot.kernel.sysctl."net.core.somaxconn" = 1024;

  services.nginx.enableReload = true;
}
