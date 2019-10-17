{ config, lib, name, nodes, resources, ... }:
let
  sources = import ../nix/sources.nix;

  pkgs = import ../nix { };
  inherit (pkgs) jormungandr-cli jormungandr;
  inherit (pkgs.packages) pp;
  inherit (builtins) filter attrValues mapAttrs;

  compact = l: filter (e: e != null) l;
  peerAddress = nodeName: node:
    let jcfg = node.config.services.jormungandr;
    in if nodeName != name && (jcfg.enable or false)
    && (__length jcfg.secrets-paths == 0) then
      let
        publicKeyCmd =
          pkgs.runCommand "publicKey" { buildInputs = [ jormungandr-cli ]; } ''
            echo ${jcfg.privateId} | jcli key to-public > $out
          '';
      in {
        address = jcfg.publicAddress;
        id = lib.fileContents publicKeyCmd;
      }
    else
      null;
  trustedPeers = compact (attrValues (mapAttrs peerAddress nodes));

  privateIds = __fromJSON (__readFile (../secrets/jormungandr-private-ids.json));
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
    package = jormungandr;
    jcliPackage = jormungandr-cli;
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
    privateId = privateIds."${name}" or (abort "run ./scripts/update-jormungandr-private-ids.rb");
  };
  systemd.services.jormungandr.serviceConfig.MemoryMax = "14G";


  networking.firewall.allowedTCPPorts = [ 3000 ];

  environment.variables.JORMUNGANDR_RESTAPI_URL =
    "http://${config.services.jormungandr.rest.listenAddress}/api";

  environment.systemPackages = with pkgs; [ jormungandr-cli janalyze ];

  services.jormungandr-monitor = {
    enable = true;
    genesisYaml =
      if (builtins.pathExists ../static/genesis.yaml)
      then ../static/genesis.yaml
      else null;
  };

  services.nginx.enableReload = true;
}
