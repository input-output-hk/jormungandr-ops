{ config, lib, name, nodes, resources, ... }:
let
  sources = import ../nix/sources.nix;

  pkgs = import ../nix { };
  inherit (pkgs.packages) pp;
  inherit (builtins) filter attrValues mapAttrs;
  globals = import ../globals.nix;
  environment = pkgs.jormungandrLib.environments.${environment};

  compact = l: filter (e: e != null) l;
  peerAddress = nodeName: node:
    if node.config.node.isRelay && (nodeName != name) then
      {
        address = node.config.services.jormungandr.publicAddress;
        id = publicIds.${nodeName};
      }
    else
      null;
  trustedPeers = compact (attrValues (mapAttrs peerAddress nodes));

  publicIds = __fromJSON (__readFile (../secrets/jormungandr-public-ids.json));
in {
  imports = [
    (sources.jormungandr-nix + "/nixos")
    ./monitoring-exporters.nix
    ./common.nix
  ];
  disabledModules = [ "services/networking/jormungandr.nix" ];

  deployment.ec2.securityGroups = [
    resources.ec2SecurityGroups."allow-jormungandr-${config.node.region}"
    resources.ec2SecurityGroups."allow-monitoring-collection-${config.node.region}"
  ];

  services.jormungandr = {
    enable = true;
    withBackTraces = true;
    package = pkgs.jormungandrEnv.packages.jormungandr;
    jcliPackage = pkgs.jormungandrEnv.packages.jcli;
    rest.cors.allowedOrigins = [ ];
    publicAddress = if config.deployment.targetEnv == "ec2" then
      "/ip4/${resources.elasticIPs."${name}-ip".address}/tcp/3000"
    else
      "/ip4/${config.networking.publicIPv4}/tcp/3000";
    listenAddress = "/ip4/0.0.0.0/tcp/3000";
    rest.listenAddress = "${config.networking.privateIPv4}:3001";
    logger = {
      level = "info";
      output = "stderr";
    };
    inherit trustedPeers;
    maxConnections = 11000;
    publicId = publicIds."${name}" or (abort "run ./scripts/update-jormungandr-public-ids.rb");
  };
  systemd.services.jormungandr.serviceConfig.MemoryMax = "7G";


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
    genesisYaml =
      if (builtins.pathExists ../static/genesis.yaml)
      then ../static/genesis.yaml
      else null;
  };

  services.nginx.enableReload = true;
}
